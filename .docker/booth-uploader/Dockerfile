FROM chromium-node:latest

RUN mkdir /app
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENTRYPOINT [ "node", "index.js" ]