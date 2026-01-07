# Horcrux Landing Page

Simple landing page that redirects `https://horcruxbackup.com/invite/...` URLs to `horcrux://horcruxbackup.com/invite/...` to open the Horcrux mobile app.

## Build and Run

### Local Development
```bash
# Build the Docker image
docker build -t horcrux-landing .

# Run locally on port 8080
docker run -p 8080:80 horcrux-landing

# Test it
open http://localhost:8080/invite/test123?vault=abc&name=Test&owner=def&relays=wss://relay.example.com
```

### Production Deployment
```bash
# Build the image
docker build -t horcrux-landing .

# Run on your server (port 80)
docker run -d --name horcrux-landing -p 80:80 --restart unless-stopped horcrux-landing
```

### With Docker Compose
Create a `docker-compose.yml`:
```yaml
version: '3.8'
services:
  landing:
    build: .
    ports:
      - "80:80"
    restart: unless-stopped
```

Then run:
```bash
docker-compose up -d
```

### Behind a Reverse Proxy (Recommended)
If you're using nginx or another reverse proxy with SSL:
```nginx
server {
    listen 443 ssl http2;
    server_name horcruxbackup.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then run the container on port 8080:
```bash
docker run -d --name horcrux-landing -p 8080:80 --restart unless-stopped horcrux-landing
```

## How It Works

1. User clicks `https://horcruxbackup.com/invite/{code}?vault=...&owner=...&relays=...` in email/browser
2. Landing page loads and immediately redirects to `horcrux://horcruxbackup.com/invite/...`
3. If Horcrux app is installed, it opens automatically
4. If not installed (or redirect fails), fallback UI is shown after 3 seconds

## Testing URLs

The page preserves the full path and query parameters, so any of these work:
- `https://horcruxbackup.com/invite/abc123?vault=xyz&owner=pubkey&relays=wss://relay.com`
- `http://localhost:8080/invite/test?vault=v1&owner=key1&relays=wss://test.com`

## Customization

Edit `index.html` to customize:
- Colors and styling
- Logo (currently using 🔐 emoji)
- Text and messaging
- Timeout duration (currently 3 seconds)
