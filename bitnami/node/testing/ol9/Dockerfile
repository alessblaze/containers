# Copyright Aless Microsystems. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
ARG NODE_VERSION=22.16.0
ARG PYTHON_VERSION=3.13.3
FROM oraclelinux:9 AS builder
ARG NODE_VERSION
ARG PYTHON_VERSION
RUN dnf update -y && dnf config-manager --set-enabled ol9_codeready_builder
RUN dnf install -y \
  gcc gcc-c++ gcc-toolset-12 make \
  openssl-devel zlib-devel bzip2 bzip2-devel \
  sqlite sqlite-devel readline-devel \
  ncurses-devel libffi-devel \
  xz-devel gettext wget tar xz
RUN mkdir -vp /tmp/source/node \
   && cd /tmp/source/node \
   && wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz \
   && tar -xvf node-v${NODE_VERSION}.tar.gz 

RUN mkdir -vp /tmp/source/python \
  && cd /tmp/source/python \
  && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
  && tar -xvf Python-${PYTHON_VERSION}.tar.xz

RUN cd /tmp/source/python/Python-${PYTHON_VERSION} \
  && CC=gcc \
  CFLAGS='-s' \
  LDFLAGS='-Wl,-rpath=/opt/bitnami/common/lib -L/opt/bitnami/common/lib -Wl,-rpath=/opt/bitnami/python/lib -L/opt/bitnami/python/lib' \
  CPPFLAGS='-I/opt/bitnami/common/include -I/opt/bitnami/python/include' ./configure \
  --prefix=/opt/bitnami/python \
  --enable-shared \
  && make -j10 \
  && make install \
  && cd /opt/bitnami/python/bin \
  && ln -s python3 python \
  && ln -s pip3 pip
 
ENV PATH="/opt/bitnami/python/bin:$PATH" 

RUN cd /tmp/source/node/node-v${NODE_VERSION} \
    && scl enable gcc-toolset-12 "bash -c ' \
        echo \"Starting Node.js build for version \${NODE_VERSION} with GCC Toolset 12...\" && \
        case \"\${NODE_VERSION}\" in \
            20.*) \
                echo \"Applying configure flags for Node.js v20...\" && \
                ./configure \
                --prefix=/opt/bitnami/node \
                --shared-openssl \
                --with-intl=small-icu \
                --v8-enable-object-print \
                --v8-enable-short-builtin-calls \
                ;; \
            22.*) \
                echo \"Applying configure flags for Node.js v22...\" && \
                ./configure \
                --prefix=/opt/bitnami/node \
                --shared-openssl \
                --with-intl=small-icu \
                --v8-enable-object-print \
                --v8-enable-maglev \
                --v8-enable-short-builtin-calls \
                ;; \
            24.*) \
                echo \"Applying configure flags for Node.js v24...\" && \
                ./configure \
                --prefix=/opt/bitnami/node \
                --shared-openssl \
                --with-intl=small-icu \
                --v8-enable-object-print \
                --v8-enable-short-builtin-calls \
                ;; \
            *) \
                echo \"Error: Unsupported Node.js version for specific build flags: \${NODE_VERSION}\" && \
                echo \"Please add a case for this version or adjust NODE_VERSION.\" && \
                exit 1 \
                ;; \
        esac \
        && echo \"Configuration complete. Starting make...\" && \
        make -j16 \
        && echo \"Make complete. Starting install...\" && \
        make install \
        && echo \"Node.js build and install complete for v\${NODE_VERSION}.\" \
    '"

ENV PATH="/opt/bitnami/python/bin:/opt/bitnami/node/bin:$PATH"

RUN cd /opt/bitnami/node/bin \
   && npm install -g pnpm \
   && corepack enable


FROM oraclelinux:9-slim

ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"
ARG TARGETARCH

LABEL org.opencontainers.image.base.name="docker.io/oraclelinux:9" \
      org.opencontainers.image.created="2025-05-22T09:05:08Z" \
      org.opencontainers.image.description="Application packaged by Aless Microsystems." \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/node/README.md" \
      org.opencontainers.image.ref.name="22.16.0-ol9-ams" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/node" \
      org.opencontainers.image.title="node" \
      org.opencontainers.image.vendor="Aless Microsystems." \
      org.opencontainers.image.version="22.16.0"

ENV OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="ol9" \
    OS_NAME="linux"

COPY --from=builder /opt/bitnami /opt/bitnami
COPY prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN microdnf install -y \
  gcc gcc-c++ make \
  ca-certificates \
  curl \
  git \
  bzip2 bzip2-devel \
  libffi libffi-devel \
  xz xz-devel \
  ncurses ncurses-devel \
  readline readline-devel \
  sqlite sqlite-devel \
  openssl openssl-devel \
  glibc-devel libstdc++ \
  zlib zlib-devel \
  pkgconf-pkg-config \
  procps-ng \
  unzip \
  wget \
  findutils \
  gcc-toolset-12
RUN mkdir -p /tmp/bitnami/pkg/cache/ ; cd /tmp/bitnami/pkg/cache/ || exit 1 ; \
    COMPONENTS=( \
#      "python-3.13.3-4-linux-${OS_ARCH}-debian-12" \
#      "node-22.15.0-0-linux-${OS_ARCH}-debian-12" \
    ) ; \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz.sha256" -O ; \
      fi ; \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" ; \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner ; \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done
RUN microdnf update -y && microdnf remove python -y && microdnf clean all
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
RUN mkdir /.npm && chmod g+rwX /.npm
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS    90/' /etc/login.defs && \
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS    0/' /etc/login.defs && \
    sed -i 's/^# *minlen = 8/minlen = 8/' /etc/security/pwquality.conf

COPY rootfs /
RUN /opt/bitnami/scripts/node/postunpack.sh
ENV APP_VERSION="22.16.0" \
    BITNAMI_APP_NAME="node" \
    PATH="/opt/bitnami/python/bin:/opt/bitnami/node/bin:$PATH"
EXPOSE 3000

WORKDIR /app
CMD [ "node" ]
