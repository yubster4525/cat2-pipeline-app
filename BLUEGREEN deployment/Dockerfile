FROM node:18-alpine
WORKDIR /usr/src/app

COPY app/package.json ./
RUN npm install --production && npm cache clean --force

COPY app ./
ENV PORT=3000
EXPOSE 3000
CMD ["npm", "start"]
