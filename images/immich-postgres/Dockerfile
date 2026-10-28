# Debian Bookworm security patches on the already verified PostgreSQL14.24 derivative.
# Keep the server/client/libpq and vendor extension packages and binaries identical.
FROM registry.milanchis.com/immich-postgres:14.24-vchord0.4.3-20261028-4eef06f3@sha256:4eef06f313181e9ce5812224f6b5c888bf381f071e2a0aafdb5ae563bf433f07
COPY base-packages.lock extensions.sha256 /tmp/security-build/
RUN set -eu; \
    apt-get update; \
    apt-mark hold postgresql-14 postgresql-client-14 postgresql-14-vchord vectors-pg14 libpq5 postgresql-common postgresql-client-common postgresql-common-dev; \
    xargs -r apt-get install -y --no-remove --no-install-recommends --only-upgrade < /tmp/security-build/base-packages.lock; \
    sha256sum -c /tmp/security-build/extensions.sha256; \
    test "$(dpkg-query -W -f='${Version}' postgresql-14)" = '14.24-1.pgdg12+2'; \
    test "$(dpkg-query -W -f='${Version}' postgresql-client-14)" = '14.24-1.pgdg12+2'; \
    test "$(dpkg-query -W -f='${Version}' libpq5)" = '18.6-1.pgdg12+2'; \
    test "$(dpkg-query -W -f='${Version}' postgresql-14-vchord)" = '0.4.3-1'; \
    test "$(dpkg-query -W -f='${Version}' vectors-pg14)" = '0.2.0'; \
    rm -rf /var/lib/apt/lists/* /tmp/security-build; \
    postgres --version; pg_dump --version
