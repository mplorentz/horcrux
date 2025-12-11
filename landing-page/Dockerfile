FROM nginx:alpine

# Copy the landing page
COPY index.html /usr/share/nginx/html/index.html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
