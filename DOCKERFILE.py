# Use a minimal base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the server script
COPY src/server.py /app/server.py

# Install dependencies
RUN pip install requests flask

# Expose the port
EXPOSE 8000

# Run the server
CMD ["python", "server.py"]
