# webhook-gateway

## Run
```bash
docker run -it --rm -p 8080:8080 \
  -v $(pwd)/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro \
  -v $(pwd)/lua:/lua:ro \
  openresty/openresty:alpine
