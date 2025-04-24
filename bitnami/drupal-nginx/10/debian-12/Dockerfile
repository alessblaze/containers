# Copyright Aless Microsystems.
# SPDX-License-Identifier: APACHE-2.0

FROM docker.io/bitnami/minideb:bookworm

ARG TARGETARCH
ARG CTOOLS_VERSION=4.1.0
ARG SMTP_VERSION=8.x-1.4
ARG DRUPAL_VERSION=10.4.6
LABEL org.opencontainers.image.base.name="docker.io/bitnami/minideb:bookworm" \
      org.opencontainers.image.created="2025-04-24T18:08:01Z" \
      org.opencontainers.image.description="Application packaged by Aless Microsystems" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="10.4.6-debian-12-ams" \
      org.opencontainers.image.title="drupal-nginx" \
      org.opencontainers.image.vendor="Aless Microsystems" \
      org.opencontainers.image.version="10.4.6"

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-12" \
    OS_NAME="linux"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gnupg libaudit1 libbrotli1 libbsd0 libbz2-1.0 libcap-ng0 libcom-err2 libcrypt1 libcurl4 libexpat1 libffi8 libfftw3-double3 libfontconfig1 libfreetype6 libgcc-s1 libgcrypt20 libglib2.0-0 libgmp10 libgnutls30 libgomp1 libgpg-error0 libgssapi-krb5-2 libhashkit2 libhogweed6 libicu72 libidn2-0 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblcms2-2 libldap-2.5-0 liblqr-1-0 libltdl7 liblzma5 libmagickcore-6.q16-6 libmagickwand-6.q16-6 libmd0 libmemcached11 libncurses6 libnettle8 libnghttp2-14 libonig5 libp11-kit0 libpam0g libpcre2-8-0 libpcre3 libpng16-16 libpq5 libpsl5 libreadline8 librtmp1 libsasl2-2 libsodium23 libsqlite3-0 libssh2-1 libssl3 libstdc++6 libsybdb5 libtasn1-6 libtidy5deb1 libtinfo6 libunistring2 libuuid1 libwebp7 libx11-6 libxau6 libxcb1 libxdmcp6 libxext6 libxml2 libxslt1.1 libzip4 libzstd1 openssl procps unzip zlib1g wget libgeoip1
RUN mkdir -p /tmp/bitnami/pkg/cache/ ; cd /tmp/bitnami/pkg/cache/ ; \
    COMPONENTS=( \
      "php-8.3.20-3-linux-${OS_ARCH}-debian-12" \
      "nginx-1.27.5-0-linux-${OS_ARCH}-debian-12" \
      "mysql-client-11.4.5-2-linux-${OS_ARCH}-debian-12" \
      "render-template-1.0.7-15-linux-${OS_ARCH}-debian-12" \
#      "drupal-10.3.10-0-linux-${OS_ARCH}-debian-12" \
    ) ; \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
      fi ; \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" ; \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' ; \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV PATH="/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/nginx/sbin:/opt/bitnami/mysql/bin:/opt/bitnami/common/bin:/opt/bitnami/drupal/vendor/bin:$PATH"
RUN mkdir -v /tmp/drupal-ctools
RUN cd /tmp/drupal-ctools \
    && wget https://ftp.drupal.org/files/projects/ctools-${CTOOLS_VERSION}.tar.gz \
    && tar -xf ctools-${CTOOLS_VERSION}.tar.gz \
    && cd /tmp/drupal-ctools/ctools \
    && COMPOSER_ALLOW_SUPERUSER=1 /opt/bitnami/php/bin/php  /opt/bitnami/php/bin/composer install \
    && mkdir -p /opt/bitnami/drupal-plugin-ctools \
    && cp -r /tmp/drupal-ctools/ctools/. /opt/bitnami/drupal-plugin-ctools
RUN mkdir -v /tmp/smtp \
    && cd /tmp/smtp \
    && wget https://ftp-origin.drupal.org/files/projects/smtp-${SMTP_VERSION}.tar.gz \
    && tar -xf smtp-${SMTP_VERSION}.tar.gz \
    && mkdir -p /opt/bitnami/drupal/modules/contrib/smtp \
    && cp -r /tmp/smtp/smtp/. /opt/bitnami/drupal/modules/contrib/smtp
RUN mkdir -v /tmp/drupal \
    && cd /tmp/drupal \
    && wget https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz \
    && tar -xf drupal-${DRUPAL_VERSION}.tar.gz && cd /tmp/drupal/drupal-${DRUPAL_VERSION} \
    && COMPOSER_ALLOW_SUPERUSER=1 /opt/bitnami/php/bin/php  /opt/bitnami/php/bin/composer install \
    && COMPOSER_ALLOW_SUPERUSER=1 /opt/bitnami/php/bin/php  /opt/bitnami/php/bin/composer  require drush/drush \
    && COMPOSER_ALLOW_SUPERUSER=1 /opt/bitnami/php/bin/php  /opt/bitnami/php/bin/composer  require phpmailer/phpmailer \
    && mkdir -p /opt/bitnami/drupal \
    && cp -r /tmp/drupal/drupal-${DRUPAL_VERSION}/. /opt/bitnami/drupal

RUN chmod g+rwX /opt/bitnami
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

COPY rootfs /
RUN /opt/bitnami/scripts/nginx/postunpack.sh
RUN /opt/bitnami/scripts/php/postunpack.sh
RUN /opt/bitnami/scripts/nginx-php-fpm/postunpack.sh
RUN /opt/bitnami/scripts/drupal/postunpack.sh
RUN /opt/bitnami/scripts/mysql-client/postunpack.sh
ENV APP_VERSION="10.4.6" \
    BITNAMI_APP_NAME="drupal-nginx" \
    NGINX_HTTPS_PORT_NUMBER="" \
    NGINX_HTTP_PORT_NUMBER="" \
    PATH="/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/nginx/sbin:/opt/bitnami/mysql/bin:/opt/bitnami/common/bin:/opt/bitnami/drupal/vendor/bin:$PATH"

EXPOSE 8080 8443

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/drupal/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/nginx-php-fpm/run.sh" ]
