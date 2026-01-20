FROM node:20-bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install Dependencies
COPY package*.json ./
RUN npm ci

# 2. Build Project
COPY . .
RUN npm run build

# 3. Install OpenSeal
# We expect the 'openseal' binary to be in the root of the build context
# (The build_docker.sh script handles this)
COPY openseal /usr/local/bin/openseal
RUN chmod +x /usr/local/bin/openseal

# 4. Expose Port
EXPOSE 1999

# 5. Run with OpenSeal
# Using the standard 3000 port internally (application), mapped to 1999 externally by OpenSeal
# But wait, the user wants "openseal run --app dist_opensealed --port 1999"
# This means OpenSeal LISTENS on 1999.
CMD ["openseal", "run", "--app", "dist_opensealed", "--port", "1999"]
