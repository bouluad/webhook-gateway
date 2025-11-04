# NGINX + Lua Webhook Gateway

This gateway:
- Receives GitHub webhooks on `/webhook1`, `/webhook2`, etc.
- Validates HMAC SHA-256 signature
- Logs repository info
- Forwards to the appropriate Jenkins endpoint

## Run with Docker
```bash
docker run -it --rm -p 8080:8080 \
  -v $(pwd)/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro \
  -v $(pwd)/lua:/lua:ro \
  openresty/openresty:alpine
