#!/usr/bin/env node
const http = require('http');

const baseUrl = 'http://localhost:3000/mcp';
const authToken = process.env.MCP_AUTH_TOKEN;

let sessionId = null;

// Read from stdin and send to HTTP server
process.stdin.on('data', async (data) => {
  try {
    const message = JSON.parse(data.toString());

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        'Authorization': `Bearer ${authToken}`
      }
    };

    if (sessionId) {
      options.headers['Mcp-Session-Id'] = sessionId;
    }

    const req = http.request(baseUrl, options, (res) => {
      if (res.headers['mcp-session-id']) {
        sessionId = res.headers['mcp-session-id'];
      }

      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        // Handle SSE format (event: message\ndata: {...})
        const lines = responseData.split('\n');
        const dataLine = lines.find(line => line.startsWith('data: '));
        if (dataLine) {
          const jsonData = dataLine.substring(6); // Remove 'data: ' prefix
          process.stdout.write(jsonData + '\n');
        } else {
          process.stdout.write(responseData + '\n');
        }
      });
    });

    req.on('error', (error) => {
      console.error('Request error:', error);
    });

    req.write(JSON.stringify(message));
    req.end();
  } catch (error) {
    console.error('Parse error:', error);
  }
});

process.stdin.resume();
