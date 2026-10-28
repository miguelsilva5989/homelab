# Keep the deployed PostgreSQL major and vector-extension binaries unchanged.
# The upstream image still bundles PostgreSQL 14.19; update only its database
# server/client packages until the separate PostgreSQL major migration.
# This image passed a full Immich database restore with VectorChord 0.4.3 and
# pgvector 0.8.0. PostgreSQL 14 reaches end of support on 2026-11-12.
FROM ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23
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
