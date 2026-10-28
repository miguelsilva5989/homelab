# Keep the deployed PostgreSQL major and vector-extension binaries unchanged.
# The upstream image still bundles PostgreSQL 14.19; update only its database
# server/client packages until the separate PostgreSQL major migration.
# This image passed a full Immich database restore with VectorChord 0.4.3 and
# pgvector 0.8.0. PostgreSQL 14 reaches end of support on 2026-11-12.
FROM ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0@sha256:1a078b237c1d9b420b0ee59147386b4aa60d3a07a8e6a402fc84a57e41b043a4
ENV PG_VERSION=14.24-1.pgdg12+2
RUN set -eu; \
    apt-get update; \
    apt-get install -y --no-install-recommends --only-upgrade \
      postgresql-14=14.24-1.pgdg12+2 \
      postgresql-client-14=14.24-1.pgdg12+2 \
      libpq5=18.6-1.pgdg12+2; \
    rm -rf /var/lib/apt/lists/*; \
    postgres --version; \
    pg_dump --version
