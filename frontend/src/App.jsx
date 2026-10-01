import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import Plotly from 'react-plotly.js';
import './App.css';

const App = () => {
  const [query, setQuery] = useState('');
  const [conversation, setConversation] = useState([]);
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [conversation]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!query.trim()) return;

    const userMessage = { type: 'user', content: query };
    setConversation(prev => [...prev, userMessage]);
    setLoading(true);
    
    const currentQuery = query;
    setQuery('');

    try {
      const response = await axios.post('http://localhost:8000/query', { query: currentQuery });
      
      const botMessage = {
        type: 'bot',
        content: response.data.summary || 'No summary available',
        data: response.data.data || [],
        visualization: response.data.visualization,
        followUps: response.data.follow_ups || []  // Add follow-ups
      };
      
      setConversation(prev => [...prev, botMessage]);
    } catch (err) {
      const errorMessage = {
        type: 'bot',
        content: `Error: ${err.message}`,
        isError: true
      };
      setConversation(prev => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  const handleFollowUpClick = (followUp) => {
    setQuery(followUp);
    // Auto-submit after a short delay
    setTimeout(() => {
      document.querySelector('form')?.requestSubmit();
    }, 100);
  };

  const renderMessage = (message, index) => {
    if (message.type === 'user') {
      return (
        <div key={index} className="flex justify-end mb-4">
          <div className="bg-blue-500 text-white rounded-lg py-2 px-4 max-w-xs lg:max-w-md">
            <p className="text-sm">{message.content}</p>
          </div>
        </div>
      );
    }

    return (
      <div key={index} className="flex justify-start mb-6">
        <div className="bg-gray-100 rounded-lg p-4 max-w-xs lg:max-w-2xl shadow-sm">
          {/* Summary Text */}
          <div className="mb-3">
            <p className="text-gray-800 text-sm leading-relaxed">{message.content}</p>
          </div>

          {/* Data Table */}
          {message.data && message.data.length > 0 && (
            <div className="mb-3">
              <div className="overflow-x-auto border rounded-lg">
                <table className="w-full text-sm border-collapse">
                  <thead>
                    <tr className="bg-gray-200">
                      {Object.keys(message.data[0]).map((key) => (
                        <th key={key} className="border p-2 text-left font-medium text-gray-700">{key}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {message.data.map((row, rowIndex) => (
                      <tr key={rowIndex} className="even:bg-gray-50">
                        {Object.values(row).map((value, cellIndex) => (
                          <td key={cellIndex} className="border p-2">{value}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Visualization */}
          {message.visualization && 
           message.visualization !== "No data available for visualization." &&
           !message.visualization.startsWith("Error") && (
            <div className="mb-2">
              <div className="border rounded-lg p-3 bg-white">
                <Plotly
                  data={JSON.parse(message.visualization).data}
                  layout={JSON.parse(message.visualization).layout}
                  config={{ displayModeBar: false, responsive: true }}
                  className="w-full h-64"
                />
              </div>
            </div>
          )}

          {/* Follow-up Suggestions */}
          {message.followUps && message.followUps.length > 0 && (
            <div className="mt-3 pt-3 border-t border-gray-200">
              <div className="text-xs text-gray-600 mb-2">💡 Try asking:</div>
              <div className="flex flex-wrap gap-2">
                {message.followUps.map((followUp, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleFollowUpClick(followUp)}
                    className="text-xs bg-blue-50 text-blue-700 hover:bg-blue-100 px-3 py-1 rounded transition-colors border border-blue-200 hover:border-blue-300"
                  >
                    {followUp}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Error State */}
          {message.isError && (
            <div className="text-red-500 text-sm italic">
              Failed to process query
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex flex-col">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold text-gray-800 flex items-center">
            <span className="mr-2">🤖</span>
            Talk to Data
          </h1>
          <p className="text-gray-600 text-sm mt-1">
            Ask questions about your company data and get instant insights
          </p>
        </div>
      </div>

      {/* Chat Container */}
      <div className="flex-1 overflow-hidden flex flex-col max-w-4xl mx-auto w-full px-4 py-6">
        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto mb-4 space-y-4">
          {conversation.length === 0 && (
            <div className="text-center text-gray-500 py-12">
              <div className="text-4xl mb-4">📊</div>
              <h3 className="text-lg font-semibold mb-2">Welcome to Talk to Data!</h3>
              <p className="text-sm">Ask questions like:</p>
              <div className="mt-3 space-y-1 text-xs text-gray-600">
                <p>"How many employees are in each department?"</p>
                <p>"What are the highest and lowest salaries?"</p>
                <p>"Show me average salary by job title"</p>
              </div>
            </div>
          )}
          
          {conversation.map(renderMessage)}
          
          {loading && (
            <div className="flex justify-start mb-4">
              <div className="bg-gray-100 rounded-lg p-4">
                <div className="flex space-x-2">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="bg-white rounded-lg shadow-lg border p-4">
          <form onSubmit={handleSubmit} className="flex gap-3">
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Ask about your data... (e.g., count employees in each department)"
              className="flex-1 p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              disabled={loading}
            />
            <button
              type="submit"
              disabled={loading || !query.trim()}
              className="bg-blue-500 text-white px-6 py-3 rounded-lg hover:bg-blue-600 disabled:bg-blue-300 disabled:cursor-not-allowed transition-colors flex items-center"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Analyzing...
                </>
              ) : (
                <>
                  <span className="mr-2">📤</span>
                  Send
                </>
              )}
            </button>
          </form>
          <div className="mt-3 flex flex-wrap gap-2 text-xs text-gray-500">
            <span>Try:</span>
            <button 
              onClick={() => setQuery("count employees in each department")}
              className="bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded transition-colors"
            >
              Employee count
            </button>
            <button 
              onClick={() => setQuery("show highest and lowest salaries")}
              className="bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded transition-colors"
            >
              Salary range
            </button>
            <button 
              onClick={() => setQuery("average salary by department")}
              className="bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded transition-colors"
            >
              Dept averages
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};



export default App;