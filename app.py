import os
import re
from dotenv import load_dotenv
from typing import TypedDict, Annotated, Sequence
from langgraph.graph import StateGraph, END
from langchain_core.messages import HumanMessage, AIMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_groq import ChatGroq
import pandas as pd
import plotly.express as px
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy import create_engine, text
import traceback 
import logging

load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

# Enable CORS for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model for query input
class QueryInput(BaseModel):
    query: str

# Initialize GroqCloud model
try:
    llm = ChatGroq(
        api_key=os.environ["GROQ_API_KEY"],
        model_name="llama-3.3-70b-versatile"
    )
except Exception as e:
    logger.error(f"Failed to initialize Groq API: {str(e)}")
    raise

# Define state
class AgentState(TypedDict):
    messages: Annotated[Sequence[AIMessage], "Messages in the conversation"]
    sql_query: str
    data: pd.DataFrame
    visualization: str
    schema_info: str
    summary: str 
    follow_ups: list

# Database connection
def get_db_engine():
    try:
        db_path = "test_hr.db"
        engine = create_engine(f"sqlite:///{db_path}")
        
        import sqlite3
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute("DROP TABLE IF EXISTS employees")
        cursor.execute("DROP TABLE IF EXISTS departments")
        
        cursor.execute("""
            CREATE TABLE departments (
                department_id INTEGER PRIMARY KEY,
                department_name TEXT,
                location TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE employees (
                employee_id INTEGER PRIMARY KEY,
                first_name TEXT,
                last_name TEXT,
                department_id INTEGER,
                job_title TEXT,
                salary DECIMAL(10,2)
            )
        """)
        
        cursor.execute("""
            INSERT INTO departments (department_id, department_name, location) VALUES
            (1, 'Engineering', 'San Francisco'),
            (2, 'Sales', 'New York'),
            (3, 'Marketing', 'Chicago'),
            (4, 'HR', 'Boston')
        """)
        
        cursor.execute("""
            INSERT INTO employees (employee_id, first_name, last_name, department_id, job_title, salary) VALUES
            (1, 'John', 'Doe', 1, 'Software Engineer', 95000),
            (2, 'Jane', 'Smith', 1, 'Senior Developer', 120000),
            (3, 'Alice', 'Johnson', 2, 'Sales Manager', 85000),
            (4, 'Bob', 'Williams', 2, 'Sales Rep', 65000),
            (5, 'Carol', 'Brown', 3, 'Marketing Specialist', 70000),
            (6, 'David', 'Jones', 4, 'HR Manager', 80000)
        """)
        
        conn.commit()
        conn.close()
        
        print("✅ SQLite database created with test HR data!")
        return engine
    except Exception as e:
        logger.error(f"Failed to create database engine: {str(e)}")
        raise

def get_schema_info():
    try:
        engine = get_db_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT m.name as table_name, p.name as column_name, p.type as data_type
                FROM sqlite_master m
                JOIN pragma_table_info(m.name) p
                WHERE m.type = 'table'
                ORDER BY m.name, p.cid
            """)
            schema_df = pd.read_sql(query, conn)
        
        schema_str = "Database Schema:\n"
        for table in schema_df['table_name'].unique():
            schema_str += f"\nTable: {table}\n"
            table_cols = schema_df[schema_df['table_name'] == table]
            for _, row in table_cols.iterrows():
                schema_str += f"  - {row['column_name']} ({row['data_type']})\n"
        
        return schema_str
    except Exception as e:
        logger.error(f"Error retrieving schema: {str(e)}")
        return f"Error retrieving schema: {str(e)}"

# Prompts
sql_prompt = ChatPromptTemplate.from_template(
    """You are an expert SQL query generator for a SQLite database. Below is the database schema:

    {schema_info}

    Convert the following natural language query to a valid SQL query. Return only the SQL query as a plain string, without any code block markers (e.g., ```sql, ```, or other formatting). Do not include any explanations or additional text.

    User query: {query}
    """
)

viz_prompt = ChatPromptTemplate.from_template(
    """You are an expert in generating Plotly Express visualizations. Based on the following data summary and user query, generate Python code to create an appropriate visualization using Plotly Express. 
    
    IMPORTANT RULES:
    1. Use pandas version 2.0+ compatible code - DO NOT use df.append(), use pd.concat() instead
    2. Return only the Python code as a plain string, without code block markers
    3. Do not include fig.show() or any display commands
    4. The code should only create a Plotly figure (e.g., fig = px.bar(...))
    5. Use only the provided 'data' DataFrame, 'px' for plotly.express, and 'pd' for pandas
    6. If the data has only 2-3 rows, use a bar chart
    7. Always set a title for the chart

    User query: {query}
    Data summary: {data_summary}
    Data columns: {columns}
    """
)

summary_prompt = ChatPromptTemplate.from_template(
    """You are a data analyst providing concise 2-3 sentence summaries. Based on the query and data, highlight the most important insights.

    USER QUERY: {query}
    
    DATA RESULTS:
    {data_results}
    
    VISUALIZATION TYPE: {viz_description}
    
    Provide a brief but insightful summary focusing on:
    1. Key findings from the data
    2. Any notable patterns or outliers
    3. What this means in context of the query
    
    SUMMARY:
    """
)

# LangGraph nodes
# Each function takes the current state, performs its task, and returns a new state with the relevant information added. The graph will manage the flow of data through these functions based on the defined edges.
def fetch_schema(state: AgentState) -> AgentState:
    schema_info = get_schema_info()
    return {"schema_info": schema_info}

# Converts the latest user message into an SQL query using the Groq model, ensuring that only the raw SQL string is returned without any formatting or explanations.
def nl_to_sql(state: AgentState) -> AgentState:
    try:
        query = state["messages"][-1].content
        schema_info = state["schema_info"]
        raw_sql = llm.invoke(sql_prompt.format(query=query, schema_info=schema_info)).content
        cleaned_sql = re.sub(r'```(?:sql)?\n|\n```', '', raw_sql).strip()
        logger.info(f"Generated SQL query: {cleaned_sql}")
        return {"sql_query": cleaned_sql}
    except Exception as e:
        logger.error(f"Error in nl_to_sql: {str(e)}")
        return {"sql_query": "", "messages": [AIMessage(content=f"Error generating SQL query: {str(e)}")]}

#executes the generated SQL query and retrieves data from the database, storing it in the state for further processing.
def execute_query(state: AgentState) -> AgentState:
    try:
        engine = get_db_engine()
        with engine.connect() as conn:
            logger.info(f"Executing SQL query: {state['sql_query']}")
            data = pd.read_sql(state["sql_query"], conn)
            logger.info(f"Retrieved {len(data)} rows")
            return {"data": data}
    except Exception as e:
        logger.error(f"Error executing query: {str(e)}")
        return {"data": pd.DataFrame(), "messages": [AIMessage(content=f"Error executing query: {str(e)}")]}

# Generates a visualization based on the retrieved data and the user's original query, using the Groq model to create Plotly Express code. The generated code is executed to produce a visualization, which is then stored in the state.
def generate_visualization(state: AgentState) -> AgentState:
    if state["data"].empty:
        return {"visualization": "No data available for visualization."}
    
    query = state["messages"][-1].content
    data = state["data"]
    data_summary = data.describe().to_string()
    columns = ", ".join(data.columns.tolist())
    
    try:
        viz_code = llm.invoke(viz_prompt.format(
            query=query, 
            data_summary=data_summary,
            columns=columns
        )).content
        cleaned_viz_code = re.sub(r'```(?:python)?\n|\n```', '', viz_code).strip()
        logger.info(f"Generated visualization code: {cleaned_viz_code}")
        
        local_vars = {
            "px": px,
            "pd": pd,
            "data": data,
            "__builtins__": {"__import__": __import__}
        }
        exec(cleaned_viz_code, {}, local_vars)
        fig = local_vars.get("fig")
        if fig:
            return {"visualization": fig.to_json()}
        else:
            return {"visualization": "Failed to generate visualization: No figure returned."}
    except Exception as e:
        logger.error(f"Error generating visualization: {str(e)}")
        return {"visualization": f"Error generating visualization: {str(e)}"}

def generate_summary(state: AgentState) -> AgentState:
    """CRITICAL FIX: This function MUST return a dict with 'summary' key"""
    try:
        if state["data"].empty:
            logger.warning("No data available for summary")
            return {"summary": "No data available to summarize."}
        
        # Get the original user query
        user_query = None
        for msg in state["messages"]:
            if isinstance(msg, HumanMessage):
                user_query = msg.content
                break
        
        if not user_query:
            user_query = "Analyze the data"
        
        # Format data for better readability
        if len(state["data"]) > 10:
            data_preview = state["data"].head(5).to_string() + f"\n... and {len(state['data']) - 5} more rows"
        else:
            data_preview = state["data"].to_string()
        
        # Create meaningful visualization description
        viz_description = "Data visualization"
        if state.get("visualization"):
            if "bar" in state["visualization"].lower():
                viz_description = "Bar chart comparing values"
            elif "line" in state["visualization"].lower():
                viz_description = "Line chart showing trends"
            elif "scatter" in state["visualization"].lower():
                viz_description = "Scatter plot showing relationships"
        
        # Generate summary
        summary_response = llm.invoke(summary_prompt.format(
            query=user_query, 
            data_results=data_preview, 
            viz_description=viz_description
        ))
        
        summary = summary_response.content.strip()
        
        # Ensure we have a valid summary
        if not summary or len(summary) < 10:
            summary = f"Analysis of {user_query}: Found {len(state['data'])} records with key metrics."
        
        logger.info(f"✅ Generated summary: {summary}")
        
        # CRITICAL: Return a dictionary with the summary key
        return {"summary": summary}
        
    except Exception as e:
        logger.error(f"❌ Error generating summary: {str(e)}")
        fallback_summary = f"Data analysis completed. Retrieved {len(state.get('data', pd.DataFrame()))} records."
        return {"summary": fallback_summary}
    
    # Add this simple follow-up function
def generate_simple_follow_ups(state: AgentState) -> AgentState:
    """Generate simple follow-up questions based on current data"""
    try:
        logger.info(f"🔍 DEBUG: Starting follow-up generation")
        logger.info(f"🔍 DEBUG: Data empty? {state['data'].empty}")
        logger.info(f"🔍 DEBUG: Current query: {state['messages'][-1].content}")
        
        if state["data"].empty:
            logger.info("🔍 DEBUG: Data is empty, returning no follow-ups")
            return {"follow_ups": []}
        
        current_query = state["messages"][-1].content.lower()
        logger.info(f"🔍 DEBUG: Query in lowercase: {current_query}")
        
        follow_ups = []
        
        # Basic follow-up logic based on query content
        if "count" in current_query and "department" in current_query:
            follow_ups = [
                "Show average salary by department",
                "Show highest paid employees by department", 
                "Compare department sizes with salaries"
            ]
            logger.info("🔍 DEBUG: Matched department count pattern")
        elif "salary" in current_query:
            follow_ups = [
                "Show salary distribution",
                "Find employees above average salary",
                "Compare salaries by job title"
            ]
            logger.info("🔍 DEBUG: Matched salary pattern")
        elif "employee" in current_query:
            follow_ups = [
                "Show employees by location",
                "Find managers vs individual contributors",
                "Show hiring trends"
            ]
            logger.info("🔍 DEBUG: Matched employee pattern")
        else:
            # Generic follow-ups
            follow_ups = [
                "Show more details about this data",
                "Compare with other departments",
                "Find trends or patterns"
            ]
            logger.info("🔍 DEBUG: Using generic follow-ups")
        
        logger.info(f"✅ Generated follow-ups: {follow_ups}")
        return {"follow_ups": follow_ups[:3]}  # Return max 3
        
    except Exception as e:
        logger.error(f"❌ Error generating follow-ups: {str(e)}")
        logger.error(f"❌ Full error: {traceback.format_exc()}")
        return {"follow_ups": []}
def format_response(state: AgentState) -> AgentState:
    try:
        if state["data"].empty:
            response = {
                "error": "No data retrieved for your query.", 
                "data": [], 
                "visualization": state.get("visualization", ""),
                "summary": state.get("summary", "No summary available"),
                "follow_ups": state.get("follow_ups", [])
            }
        else:
            response = {
                "data": state["data"].to_dict(orient="records"),
                "visualization": state.get("visualization", ""),
                "summary": state.get("summary", "No summary generated"),
                "follow_ups": state.get("follow_ups", [])
            }
        
        logger.info(f"📦 Final response with {len(response.get('follow_ups', []))} follow-ups")
        
        return {"messages": [AIMessage(content=json.dumps(response, ensure_ascii=False))]}
        
    except Exception as e:
        logger.error(f"Error in format_response: {str(e)}")
        error_response = {
            "error": f"Formatting error: {str(e)}",
            "data": [],
            "visualization": "",
            "summary": "",
            "follow_ups": []
        }
        return {"messages": [AIMessage(content=json.dumps(error_response))]}
    
# Build the graph
workflow = StateGraph(AgentState)
workflow.add_node("fetch_schema", fetch_schema)
workflow.add_node("nl_to_sql", nl_to_sql)
workflow.add_node("execute_query", execute_query)
workflow.add_node("generate_visualization", generate_visualization)
workflow.add_node("generate_summary", generate_summary)
workflow.add_node("generate_follow_ups", generate_simple_follow_ups)
workflow.add_node("format_response", format_response)

# Define workflow connections
workflow.add_edge("fetch_schema", "nl_to_sql")
workflow.add_edge("nl_to_sql", "execute_query")
workflow.add_edge("execute_query", "generate_visualization")
workflow.add_edge("generate_visualization", "generate_summary")
workflow.add_edge("generate_summary", "generate_follow_ups")
workflow.add_edge("generate_follow_ups", "format_response")
workflow.add_edge("format_response", END)
workflow.set_entry_point("fetch_schema")
graph = workflow.compile()

# FastAPI endpoint for queries
@app.post("/query")
async def run_query(query_input: QueryInput):
    try:
        initial_state = {
            "messages": [HumanMessage(content=query_input.query)],
            "sql_query": "",
            "data": pd.DataFrame(),
            "visualization": "",
            "schema_info": "",
            "summary": ""
        }
        result = graph.invoke(initial_state)
        response = json.loads(result["messages"][-1].content)
        
        logger.info(f"🚀 API Response being sent: {json.dumps(response, indent=2)[:300]}")
        
        return response
    except Exception as e:
        logger.error(f"Error in /query endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

#.\venv\Scripts\Activate.ps1     
