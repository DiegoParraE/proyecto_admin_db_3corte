FROM python:3.12-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ backend/
COPY frontend/ frontend/
RUN chmod +x backend/entrypoint.sh

EXPOSE 5000
WORKDIR /app/backend
ENTRYPOINT ["./entrypoint.sh"]
