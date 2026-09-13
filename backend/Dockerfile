# Clipso License Server
FROM node:22-slim

ENV NODE_ENV=production
WORKDIR /app

# Install production dependencies against the committed lockfile.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# App source
COPY . .

# Run as the unprivileged user that the node image ships with.
USER node

EXPOSE 3000

# Basic container-level healthcheck (Fly also has its own; see fly.toml).
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]
