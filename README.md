# 🪙 Crypto Price Oracle API

Production-ready cryptocurrency price API designed for **OpenSeal wrapping** and verifiable computation.

## Features

- ✅ **Multi-Ticker Support**: BTC, ETH, CRO, and any Coinbase-listed asset
- ✅ **Real-Time Data**: Coinbase Public API integration
- ✅ **OpenSeal Ready**: Designed for cryptographic proof wrapping
- ✅ **Docker Packaged**: One-command deployment
- ✅ **Health Checks**: Built-in monitoring endpoints

---

## Quick Start

### Scenario 1: Local Development (Build from Source)

```bash
# Clone repository
git clone https://github.com/Gnomone/crypto-price-oracle.git
cd crypto-price-oracle

# Build Docker image
docker build -t crypto-price-oracle:v1 .

# Seal with OpenSeal
openseal build --image crypto-price-oracle:v1

# Run with OpenSeal proxy
openseal run --image crypto-price-oracle:v1 --port 8080

# Test
curl -X POST http://localhost:8080/api/v1/price \
  -H "Content-Type: application/json" \
  -H "X-OpenSeal-Wax: test123" \
  -d '{"symbol":"BTC"}'
```

### Scenario 2: Deployment (Use Pre-built Image)

> ⚠️ **Note**: Docker image not yet published to ghcr.io. Use Scenario 1 for now.

```bash
# TODO: After image is published
docker pull ghcr.io/gnomone/crypto-price-oracle:latest
openseal build --image ghcr.io/gnomone/crypto-price-oracle:latest
openseal run --image ghcr.io/gnomone/crypto-price-oracle:latest --port 8080
```

---

## API Endpoints

### Get Price

```http
GET /api/v1/price/:symbol
```

**Parameters**:
- `symbol` (string): Crypto ticker (e.g., BTC, ETH, CRO)

**Response**:
```json
{
  "symbol": "BTC",
  "price": "89553.03",
  "currency": "USD",
  "timestamp": "2026-01-22T05:30:00.000Z",
  "provider": "HighStation Demo Oracle"
}
```

**Supported Symbols**:
- `BTC` - Bitcoin
- `ETH` - Ethereum
- `CRO` - Cronos
- `SOL` - Solana
- `ADA` - Cardano
- Any Coinbase-listed asset

### Health Check

```http
GET /health
```

**Response**:
```json
{
  "status": "active",
  "service": "Crypto Price Oracle",
  "version": "1.0.0"
}
```

---

## OpenSeal Integration

This API is designed to be wrapped with [OpenSeal](https://github.com/Gnomone/openseal) for cryptographic proof of results.

### Step 1: Build Docker Image

```bash
docker build -t crypto-price-oracle:v1 .
```

### Step 2: Seal with OpenSeal

```bash
openseal build --image crypto-price-oracle:v1
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

### Step 3: Run with OpenSeal Proxy

```bash
openseal run --image crypto-price-oracle:v1 --port 8080
```

### Step 4: Query with Cryptographic Proof

```bash
curl -H "X-OpenSeal-Wax: myChallenge" http://localhost:8080/api/v1/price/BTC
```

**Response with Seal**:
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
    "price": "89553.03",
    "currency": "USD",
    "timestamp": "2026-01-22T05:30:00.000Z"
  }
}
```

**Verification**:
- `a_hash`: Identity commitment (Image Digest + Wax)
- `b_hash`: Result binding (cryptographically tied to result)
- `signature`: Ed25519 proof (verifiable by anyone)

---

## Deployment Guide

### Docker Compose

```yaml
version: '3.8'
services:
  oracle:
    image: ghcr.io/gnomone/crypto-price-oracle:latest
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
    restart: unless-stopped
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crypto-oracle
spec:
  replicas: 3
  selector:
    matchLabels:
      app: crypto-oracle
  template:
    metadata:
      labels:
        app: crypto-oracle
    spec:
      containers:
      - name: oracle
        image: ghcr.io/gnomone/crypto-price-oracle:latest
        ports:
        - containerPort: 3000
        env:
        - name: PORT
          value: "3000"
```

---

## HighStation Integration

This oracle is designed for [HighStation](https://github.com/Gnomone/HighStation) - a decentralized API marketplace.

### Register Service

```bash
curl -X POST https://api.highstation.net/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Crypto Price Oracle",
    "slug": "crypto-price-oracle",
    "endpoint": "https://your-server.com:8080",
    "openseal_verified": true
  }'
```

### MCP (Model Context Protocol) Configuration

```json
{
  "mcpServers": {
    "crypto-oracle": {
      "url": "https://your-server.com:8080",
      "tools": [
        {
          "name": "get_crypto_price",
          "description": "Get real-time cryptocurrency price with cryptographic proof",
          "parameters": {
            "symbol": {
              "type": "string",
              "description": "Crypto ticker (e.g., BTC, ETH)"
            }
          }
        }
      ]
    }
  }
}
```

---

## Development

### Prerequisites

- Node.js 20+
- Docker (for containerization)
- OpenSeal CLI (for wrapping)

### Install Dependencies

```bash
npm install
```

### Run Development Server

```bash
npm run dev
```

### Build

```bash
npm run build
```

### Test

```bash
# Unit tests
npm test

# Integration test
curl http://localhost:3000/api/v1/price/BTC
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment mode |

---

## Architecture

```
Client Request
    ↓
OpenSeal Proxy (Port 8080)
    ├─ Verify Wax
    ├─ Compute A-hash
    ↓
Crypto Oracle (Port 3000)
    ├─ Fetch Coinbase API
    ├─ Return price data
    ↓
OpenSeal Proxy
    ├─ Compute B-hash
    ├─ Sign with Ed25519
    ↓
Response with Cryptographic Seal
```

---

## Security

### OpenSeal Guarantees

- ✅ **Result Integrity**: Price data is cryptographically bound to the sealed container
- ✅ **Non-Repudiation**: Ed25519 signature proves origin
- ✅ **Replay Protection**: Wax (challenge) ensures freshness

### Container Isolation

```bash
docker run \
  --read-only \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  -p 3000:3000 \
  crypto-price-oracle:v1
```

---

## FAQ

**Q: Which exchanges are supported?**  
A: Currently Coinbase Public API. Binance integration coming soon.

**Q: Is this free to use?**  
A: Yes, the Coinbase Public API has no rate limits for spot prices.

**Q: Can I add custom data sources?**  
A: Yes, fork the repo and modify `src/index.ts`.

**Q: What about historical data?**  
A: This oracle provides real-time spot prices only.

---

## Roadmap

- [ ] Binance API integration
- [ ] Historical price data
- [ ] WebSocket streaming
- [ ] Rate limiting
- [ ] Caching layer

---

## License

MIT License - See [LICENSE](./LICENSE)

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Links

- **OpenSeal**: https://github.com/Gnomone/openseal
- **HighStation**: https://github.com/Gnomone/HighStation
- **API Documentation**: https://docs.highstation.net

---

Built with ❤️ by the HighStation team
