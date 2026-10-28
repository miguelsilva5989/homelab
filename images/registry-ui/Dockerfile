# Upstream 2.6.0 has the required UI and registry proxy behavior, but its image
# still bundles nginx 1.29.4. Copy only its static assets and startup config into
# the patched official nginx image; do not copy its old operating-system layers.
FROM joxit/docker-registry-ui:2.6.0@sha256:bb5956a6b378706f1c3a92c947d0a0c606e280460cd9e37c0198caf46399c839 AS ui

FROM nginx:1.30.6-alpine-slim@sha256:dede8895648b461178c3bc604f7eed4423efe5220b2c4d839f5eb3d34ac3f8f7
LABEL org.opencontainers.image.title="Homelab registry UI" \
      org.opencontainers.image.version="2.6.0-nginx1.30.6" \
      org.opencontainers.image.source="https://github.com/miguelsilva5989/homelab"

WORKDIR /usr/share/nginx/html/
ENV NGINX_PROXY_HEADER_Host='$http_host' \
    NGINX_LISTEN_PORT=80 \
    SHOW_CATALOG_NB_TAGS=false

COPY --from=ui /usr/share/nginx/html/ /usr/share/nginx/html/
COPY --from=ui /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=ui /docker-entrypoint.d/90-docker-registry-ui.sh /docker-entrypoint.d/90-docker-registry-ui.sh

RUN chown -R nginx:nginx /etc/nginx/ /usr/share/nginx/html/ /var/cache/nginx /var/log/nginx \
    && nginx -v
