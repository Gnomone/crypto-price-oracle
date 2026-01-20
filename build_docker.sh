#!/bin/bash
set -e

echo "🚀 Starting HighStation Oracle Build..."

# 1. Build OpenSeal Release Binary (if not present)
echo "📦 Checking OpenSeal binary..."
if [ ! -f "../openseal/target/release/openseal" ]; then
    echo "   Building OpenSeal from source..."
    cd ../openseal
    cargo build --release
    cd ../crypto-price-oracle
else
    echo "   Found existing OpenSeal build."
fi

# 2. Copy Binary to Context
echo "📋 Copying openseal binary to context..."
cp ../openseal/target/release/openseal .

# 3. Build Docker Image
echo "🐳 Building Docker Image..."
docker build -t crypto-price-oracle:latest .

echo "✅ Build Complete!"
echo "   Run with: docker run -d --name crypto-price-oracle --network highstation_network -p 1999:1999 crypto-price-oracle:latest"
