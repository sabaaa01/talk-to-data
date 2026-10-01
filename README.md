# Talk to Data

Talk to Data is a natural-language data exploration app built with FastAPI, LangChain, Groq, React, and Plotly. Ask questions about the sample HR data and explore generated visualizations.

## Run locally on Windows

Requirements: Python 3.9 or newer, Node.js, npm, and a Groq API key. Docker is not required.

1. Copy `.env.example` to `.env` and set `GROQ_API_KEY` to your new Groq API key.
2. In PowerShell, set up and start the backend:

	```powershell
	python -m venv .venv
	.\.venv\Scripts\Activate.ps1
	pip install -r requirements.txt
	uvicorn app:app --reload
	```

3. In a second PowerShell window, start the frontend:

	```powershell
	cd frontend
	npm install
	npm start
	```

Open [http://localhost:3000](http://localhost:3000). Keep both terminal windows running.

## Run with Docker

Alternatively, with Docker Compose installed, set `GROQ_API_KEY` in `.env` and run:

```powershell
docker compose up --build
```

Open [http://localhost:8000](http://localhost:8000).

Do not commit `.env` or share your API key.
