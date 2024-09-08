# Use a lightweight Linux distribution with bash
FROM alpine:3.14

# Install bash and any other necessary utilities (e.g., find)
RUN apk add --no-cache bash findutils

# Set the working directory in the container to /app for scripts
WORKDIR /app

# Copy the bash script into the /app folder
COPY consolidate_files.sh ./consolidate_files.sh
COPY CoT_prompt.txt ./CoT_prompt.txt

# Make sure the script is executable
RUN chmod +x ./consolidate_files.sh

# Change the working directory to /context for the mount point
WORKDIR /context

# Define the entry point to run the script from /app
ENTRYPOINT ["/app/consolidate_files.sh"]
