FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

# Install Node.js 20.x for React frontend
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@10.8.2 && \
    node --version && npm --version

# Copy and build React frontend
COPY frontend ./frontend
RUN cd frontend && \
    npm install --legacy-peer-deps && \
    npm install ajv@8.17.1 --save-dev && \
    npm run build || { echo "npm run build failed"; exit 1; } && \
    ls -la /app/frontend/build && \
    ls -la /app/frontend/build/static && \
    ls -la /app/frontend/build/static/js && \
    ls -la /app/frontend/build/static/css

ENV POSTGRES_HOST="db"
ENV POSTGRES_DB="sales_db"
ENV POSTGRES_USER="postgres"
ENV POSTGRES_PASSWORD="pgpasswd"

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
