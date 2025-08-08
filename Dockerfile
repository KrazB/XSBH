# Simple XSBH BIM Fragment Viewer Dockerfile  
# Optimized for Windows users  
  
FROM node:18-alpine  
  
WORKDIR /app  
  
# Install dependencies  
RUN apk add --no-cache python3 make g++  
  
# Copy package files  
COPY frontend/package*.json ./  
RUN npm install  
  
# Copy frontend source  
COPY frontend/ ./  
  
# Build the application  
RUN npm run build  
  
# Install serve to host the built files  
RUN npm install -g serve  
  
# Copy data and fragments  
COPY data/ ./data/  
COPY user-fragments/ ./data/fragments/  
  
EXPOSE 8080  
  
# Start the application  
CMD ["serve", "-s", "dist", "-l", "8080"] 
