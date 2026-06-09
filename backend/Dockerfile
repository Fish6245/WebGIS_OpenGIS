FROM node:18-alpine
WORKDIR /app
COPY . .
RUN echo '{"name":"backend","version":"1.0.0"}' > package.json
RUN echo 'const http = require("http"); const server = http.createServer((req,res) => { res.writeHead(200); res.end("API OK"); }); server.listen(3000, () => console.log("Backend running on port 3000"));' > index.js
CMD ["node", "index.js"]
