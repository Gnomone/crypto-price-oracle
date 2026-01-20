FROM node:20-bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install Dependencies
COPY package*.json ./
RUN npm ci

# 2. Build Project
COPY . .
RUN npm run build

# 3. Install OpenSeal (From GitHub Release v0.1.0)
# We download the pre-built binary directly, ensuring a clean "Public User" experience.
# Try openseal-linux first (standard), fallback to openseal just in case.
RUN curl -L -f https://github.com/kjyyoung/openseal/releases/download/v0.1.0/openseal-linux -o /usr/local/bin/openseal || \
    curl -L -f https://github.com/kjyyoung/openseal/releases/download/v0.1.0/openseal -o /usr/local/bin/openseal

RUN chmod +x /usr/local/bin/openseal

# 4. Create Sealed Bundle (Inside Container)
# This generates the 'dist_opensealed' directory that the runner expects
RUN openseal build --exec "node dist/index.js" --output dist_opensealed

# 4. Expose Port
EXPOSE 1999

# 5. Run with OpenSeal
# Using the standard 3000 port internally (application), mapped to 1999 externally by OpenSeal
# But wait, the user wants "openseal run --app dist_opensealed --port 1999"
# This means OpenSeal LISTENS on 1999.
CMD ["openseal", "run", "--app", "dist_opensealed", "--port", "1999"]
