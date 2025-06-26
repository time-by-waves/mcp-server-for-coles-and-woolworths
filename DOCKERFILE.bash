# Use a minimal base image with bash and networking tools
FROM alpine:latest

# Install required packages
RUN apk add --no-cache bash curl netcat-openbsd

# Set the working directory
WORKDIR /app

# Copy the bash server script
COPY src/server.sh /app/server.sh

# Make the script executable
RUN chmod +x /app/server.sh

# Expose the port
EXPOSE 8000

# Set environment variables
ENV PORT=8000
ENV RAPIDAPI_KEY="SIGN_UP_FREE_AND_SUBSCRIBE_TO_BOTH_APIS"

# Run the server
CMD ["./server.sh"]
