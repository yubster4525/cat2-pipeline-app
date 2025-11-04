FROM node:18-alpine AS base
WORKDIR /usr/src/app

# Copy package metadata separately for better caching
COPY app/package.json ./
RUN npm install --production && npm cache clean --force

# Copy application source
COPY app ./

EXPOSE 3000
CMD ["npm", "start"]
