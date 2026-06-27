FROM python:3.11-slim

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run the web service on container startup.
# Ensure your MCP server is listening on port 8080 (Cloud Run's default)
CMD ["python", "main.py"]
