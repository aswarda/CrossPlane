# Use official Nginx image as the base
FROM nginx:latest

# Remove default Nginx HTML files (optional)
RUN rm -rf /usr/share/nginx/html/*

# Copy your static website files to the Nginx root directory
COPY index.html /usr/share/nginx/html/index.html

# Copy a custom Nginx configuration file (optional)
#COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
