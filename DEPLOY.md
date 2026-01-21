# Quick Deployment Guide

## For Homelab/Server Deployment

### 1. Pull from GitHub

```bash
git clone https://github.com/Gnomone/crypto-price-oracle.git
cd crypto-price-oracle
```

### 2. Build Docker Image

```bash
docker build -t crypto-price-oracle:latest .
```

### 3. Option A: Run Standalone (No OpenSeal)

```bash
docker run -d \
  --name crypto-oracle \
  --restart unless-stopped \
  -p 3000:3000 \
  crypto-price-oracle:latest
```

Test:
```bash
curl -X POST http://localhost:3000/api/v1/price \
  -H "Content-Type: application/json" \
  -d '{"symbol":"BTC"}'
```

### 4. Option B: Run with OpenSeal (Recommended)

#### Install OpenSeal First

```bash
curl -L https://github.com/Gnomone/openseal/releases/latest/download/install.sh | bash
# Or build from v1-dev branch
```

#### Seal the Oracle

```bash
openseal build --image crypto-price-oracle:latest
```

This creates `openseal.json`:
```json
{
  "version": "1.0.0",
  "identity": {
    "root_hash": "sha256:...",
    "seal_version": "2.0"
  }
}
```

#### Run with OpenSeal Proxy

```bash
openseal run --image crypto-price-oracle:latest --port 8080
```

Output:
```
🐳 Starting container...
✅ Container ready
🔐 Starting OpenSeal Proxy on port 8080...
📡 Proxy Server Ready!
   Public: http://0.0.0.0:8080
```

#### Test with Cryptographic Proof

```bash
curl -X POST http://localhost:8080/api/v1/price \
  -H "Content-Type: application/json" \
  -H "X-OpenSeal-Wax: my-challenge-123" \
  -d '{"symbol":"BTC"}'
```

Response with Seal:
```json
{
  "openseal": {
    "a_hash": "18ddef79a8138634...",
    "b_hash": "493911b28d91e0ae...",
    "signature": "c327c9ef05b62792...",
    "pub_key": "d30c05d163733bae..."
  },
  "result": {
    "symbol": "BTC",
    "price": "89868.895",
    "currency": "USD",
    "timestamp": "2026-01-21T20:39:21.470Z",
    "provider": "HighStation Demo Oracle"
  }
}
```

---

## For HighStation Integration

### 1. Ensure OpenSeal is Running

```bash
openseal run --image crypto-price-oracle:latest --port 8080
```

### 2. Register to HighStation

Visit: https://www.highstation.net/dashboard

Click "Add Service" and fill in:
- **Service Name**: Crypto Price Oracle
- **Slug**: `crypto-price-oracle`
- **Endpoint URL**: `http://your-server-ip:8080`
- **OpenSeal Verified**: ✅ Yes
- **Upload** `openseal.json`

### 3. Test from Agent Playground

Navigate to: https://www.highstation.net/playground

Select "Crypto Price Oracle" and run:
```
What is the current BTC price?
```

The AI will call your service and verify the cryptographic seal!

---

## MCP (Model Context Protocol) Integration

### Claude Desktop Configuration

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or equivalent:

```json
{
  "mcpServers": {
    "crypto-oracle": {
      "command": "node",
      "args": ["path/to/mcp-wrapper.js"],
      "env": {
        "ORACLE_URL": "http://localhost:8080"
      }
    }
  }
}
```

### MCP Wrapper (Node.js)

Create `mcp-wrapper.js`:

```javascript
#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const ORACLE_URL = process.env.ORACLE_URL || "http://localhost:8080";

const server = new Server({
  name: "crypto-price-oracle",
  version: "1.0.0",
}, {
  capabilities: {
    tools: {},
  },
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "get_crypto_price",
    description: "Get real-time cryptocurrency price with cryptographic proof",
    inputSchema: {
      type: "object",
      properties: {
        symbol: {
          type: "string",
          description: "Crypto ticker (e.g., BTC, ETH, CRO)"
        }
      },
      required: ["symbol"]
    }
  }]
}));

server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "get_crypto_price") {
    const { symbol } = request.params.arguments;
    const response = await fetch(`${ORACLE_URL}/api/v1/price`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-OpenSeal-Wax": `claude-${Date.now()}`
      },
      body: JSON.stringify({ symbol })
    });
    const data = await response.json();
    return {
      content: [{
        type: "text",
        text: JSON.stringify(data, null, 2)
      }]
    };
  }
  throw new Error("Unknown tool");
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

---

## Production Considerations

### Reverse Proxy (Nginx)

```nginx
server {
    listen 443 ssl;
    server_name api.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Systemd Service

Create `/etc/systemd/system/crypto-oracle.service`:

```ini
[Unit]
Description=Crypto Price Oracle (OpenSeal)
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=your-user
WorkingDirectory=/home/your-user/crypto-price-oracle
ExecStart=/usr/local/bin/openseal run --image crypto-price-oracle:latest --port 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable crypto-oracle
sudo systemctl start crypto-oracle
sudo systemctl status crypto-oracle
```

---

## Monitoring

### Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "active",
  "service": "Crypto Price Oracle",
  "version": "1.0.0"
}
```

### Logs

```bash
# If running with systemd
sudo journalctl -u crypto-oracle -f

# If running with docker
docker logs -f <container-id>
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 8080
lsof -i :8080

# Kill if needed
kill -9 <PID>
```

### Container Won't Start

```bash
# Check Docker logs
docker logs <container-id>

# Inspect container
docker inspect <container-id>
```

### OpenSeal Digest Mismatch

```bash
# Rebuild openseal.json
openseal build --image crypto-price-oracle:latest

# Verify digest
docker inspect crypto-price-oracle:latest --format='{{.Id}}'
```

---

**Ready for production!** 🚀
