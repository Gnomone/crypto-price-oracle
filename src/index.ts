import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import axios from 'axios';

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Crypto Price Fetching Logic (Coinbase Public API)
const fetchPrice = async (symbol: string) => {
    try {
        const response = await axios.get(`https://api.coinbase.com/v2/prices/${symbol.toUpperCase()}-USD/spot`);
        return response.data.data.amount;
    } catch (error: any) {
        console.error(`[Oracle] Error fetching ${symbol} price:`, error.message);
        throw new Error(`Failed to fetch price for ${symbol}`);
    }
};

/**
 * GET /api/v1/price/:symbol
 * Returns the current spot price for a given symbol.
 */
app.get('/api/v1/price/:symbol', async (req, res) => {
    const { symbol } = req.params;
    console.log(`[Oracle] Price request: ${symbol}`);

    try {
        const price = await fetchPrice(symbol);

        // Base Result
        const result = {
            symbol: symbol.toUpperCase(),
            price: price,
            currency: 'USD',
            timestamp: new Date().toISOString(),
            provider: 'HighStation Demo Oracle'
        };

        res.json(result);
    } catch (error: any) {
        res.status(404).json({ error: error.message });
    }
});

/**
 * POST /api/v1/price
 * Returns the current spot price for a given symbol (JSON body).
 * Body: { "symbol": "BTC" }
 */
app.post('/api/v1/price', async (req, res) => {
    const { symbol } = req.body;

    if (!symbol) {
        return res.status(400).json({ error: 'Missing required field: symbol' });
    }

    console.log(`[Oracle] Price request (POST): ${symbol}`);

    try {
        const price = await fetchPrice(symbol);

        const result = {
            symbol: symbol.toUpperCase(),
            price: price,
            currency: 'USD',
            timestamp: new Date().toISOString(),
            provider: 'HighStation Demo Oracle'
        };

        res.json(result);
    } catch (error: any) {
        res.status(404).json({ error: error.message });
    }
});

/**
 * Health Check
 */
app.get('/health', (req, res) => {
    res.json({ status: 'active', service: 'Crypto Price Oracle', version: '1.0.0' });
});

/**
 * Root Route for Connectivity Check
 */
app.get('/', (req, res) => {
    res.json({
        service: 'Crypto Price Oracle',
        status: 'online',
        endpoints: [
            'GET /api/v1/price/:symbol',
            'POST /api/v1/price (body: {"symbol": "BTC"})',
            'GET /health'
        ]
    });
});

app.listen(port, () => {
    console.log(`🚀 Crypto Price Oracle Demo listening at http://localhost:${port}`);
    console.log(`Available symbols: BTC, ETH, CRO, etc.`);
});
