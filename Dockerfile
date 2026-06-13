# ──────────────────────────────────────────────
#  Dockerfile — DevFlow HTML Web App
#  Serves static files using Nginx
#  Compatible with AWS EC2 (Amazon Linux / Ubuntu)
# ──────────────────────────────────────────────

# Use official Nginx image (lightweight Alpine variant = ~23MB)
FROM nginx:1.25-alpine


# ── Remove default Nginx placeholder page ─────
RUN rm -rf /usr/share/nginx/html/*

# ── Copy your web app files into the container ─
COPY index.html      /usr/share/nginx/html/index.html

# Copy custom Nginx config (handles SPA routing, gzip, security headers)
COPY nginx.conf      /etc/nginx/conf.d/default.conf

# ── Expose port 80 (HTTP) ─────────────────────
EXPOSE 80

# ── Health check (AWS ELB / Docker will use this) ─
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

# ── Start Nginx in foreground (required for Docker) ─
CMD ["nginx", "-g", "daemon off;"]
