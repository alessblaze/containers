# Copyright Aless Microsystems. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
ARG TARGETARCH
ARG LIBGEOS_VERSION=3.13.1
ARG POSTGRES_VERSION=17.5
ARG NSS_WRAPPER_VERSION=1.1.16
ARG PG_FAILOVER_VERSION=1.1.0
ARG PGVECTOR_VERSION=0.8.0
ARG PG_BACKREST_VERSION=2.55.0 
ARG PGAUDIT_VERSION=17.1 
ARG POSTGIS_VERSION=3.4.4
ARG PROTOBUF_VERSION=3.21.12
ARG POSTGRES_INTERFACES_VERSION=17_00_0004 
ARG UNIX_ODBC_VERSION=2.3.12
ARG PL_JAVA_VERSION=1_6_9
ARG ORAFACE_VERSION=4_14_3
ARG PROTOBUF_C_VERSION=1.5.2
ARG JSON_C_VERSION=0.16-20220414
ARG GDAL_VERSION=3.10.3
ARG PROJ_VERSION=6.3.2

FROM oraclelinux:9 as builder
ARG LIBGEOS_VERSION
ARG POSTGRES_VERSION
ARG NSS_WRAPPER_VERSION
ARG PG_FAILOVER_VERSION
ARG PGVECTOR_VERSION
ARG PG_BACKREST_VERSION
ARG PGAUDIT_VERSION
ARG POSTGIS_VERSION
ARG PROTOBUF_VERSION
ARG POSTGRES_INTERFACES_VERSION
ARG UNIX_ODBC_VERSION
ARG PL_JAVA_VERSION
ARG ORAFACE_VERSION
ARG PROTOBUF_C_VERSION
ARG JSON_C_VERSION
ARG GDAL_VERSION
ARG PROJ_VERSION
ENV PATH="/opt/bitnami/postgresql/bin:/opt/bitnami/common/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/bitnami/postgresql/lib/:/opt/bitnami/common/lib:$LD_LIBRARY_PATH"
RUN dnf install -y dnf-plugins-core oracle-epel-release-el9 && dnf config-manager --set-enabled ol9_codeready_builder

#RUN apt update -y && apt install build-essential curl wget libicu-dev libicu70 icu-devtools bison libedit-dev libicu-dev uuid-dev flex libpcre3-dev liblz4-dev libxml2-utils docbook-xml docbook-xsl xsltproc fop bzip2 sqlite3 libsqlite3-dev cmake libyaml-dev libzstd-dev libbz2-dev libz-dev ninja-build meson python3-pip pkg-config libssl-dev libxml2-dev libxslt-dev libldap-dev openjdk-17-jdk maven autoconf libtool -y
RUN dnf update -y && dnf install  -y \
  gcc gcc-c++ \
  curl wget \
  libicu libicu-devel \
  bison flex \
  libedit-devel \
  libuuid-devel \
  pcre-devel \
  lz4-devel \
  libxml2 libxml2-devel \
  docbook-style-dsssl docbook-style-xsl docbook-dtds \
  libxslt \
  bzip2 \
  sqlite sqlite-devel \
  cmake \
  libyaml-devel \
  libzstd-devel bzip2-devel zlib-devel \
  ninja-build meson \
  python3-pip \
  pkgconf-pkg-config \
  openssl-devel \
  libxslt-devel \
  openldap-devel \
  java-17-openjdk java-17-openjdk-devel \
  maven \
  autoconf \
  libtool
RUN dnf install -y perl   
RUN wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz -P /tmp/sources/postgresql/ 
RUN cd /tmp/sources/postgresql/ \
   && tar -xvf postgresql-${POSTGRES_VERSION}.tar.gz \
   && cd postgresql-${POSTGRES_VERSION} \
   && ./configure  --prefix=/opt/bitnami/postgresql --with-libedit-preferred --with-openssl --with-libxml --with-libxslt --with-readline --with-icu --with-uuid=e2fs --with-ldap CFLAGS=-O2 CXXFLAGS=-O2 --with-lz4 \
   && make  world-bin --jobs=5 \
   && make  install-world-bin --jobs=5 

RUN wget https://github.com/libgeos/geos/archive/${LIBGEOS_VERSION}.tar.gz -P /tmp/sources/geos/ \
  && cd /tmp/sources/geos/ \
  && tar -xvf ${LIBGEOS_VERSION}.tar.gz \
  && cd geos-${LIBGEOS_VERSION} \
  && cmake  -DCMAKE_INSTALL_PREFIX=/opt/bitnami/postgresql -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=no -DCMAKE_BUILD_TYPE=Release \
  && make  --jobs=5 \
  && make  install --jobs=5

RUN wget https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz -P /tmp/sources/proj/ \
  && cd /tmp/sources/proj \
  && tar -xvf ${PROJ_VERSION}.tar.gz \
  && cd PROJ-${PROJ_VERSION} \
  && ./autogen.sh \
  && ./configure  --prefix=/opt/bitnami/postgresql \
  && make  --jobs=5 \ 
  && make  install --jobs=5  


RUN wget https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz -P /tmp/sources/gdal/ \
  && cd /tmp/sources/gdal/ \
  && tar -xvf gdal-${GDAL_VERSION}.tar.gz \
  && cd gdal-${GDAL_VERSION} \
  && cmake . -DCMAKE_INSTALL_PREFIX:PATH=/opt/bitnami/postgresql -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON_BINDINGS:BOOL=OFF -DGDAL_USE_EXTERNAL_LIBS:BOOL=OFF -DGDAL_USE_PROJ=ON -DGDAL_USE_GEOS=ON -B/tmp/sources/gdal/gdal-${GDAL_VERSION}/out \
  && cd /tmp/sources/gdal/gdal-${GDAL_VERSION}/out \
  && make  --jobs=5 \
  && cmake  --build . --target install


RUN wget https://github.com/json-c/json-c/archive/refs/tags/json-c-${JSON_C_VERSION}.tar.gz -P /tmp/sources/json-c/ \
  && cd /tmp/sources/json-c/ \
  && tar -xvf json-c-${JSON_C_VERSION}.tar.gz \
  && cd json-c-json-c-${JSON_C_VERSION} \
  && cmake  . -DCMAKE_INSTALL_PREFIX:PATH=/opt/bitnami/postgresql -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-Wno-error \
  && make  --jobs=5 \
  && make  install --jobs=5



RUN wget https://github.com/orafce/orafce/archive/refs/tags/VERSION_${ORAFACE_VERSION}.tar.gz -P /tmp/sources/orafce/ \
  && cd /tmp/sources/orafce/ \
  && tar -xvf VERSION_${ORAFACE_VERSION}.tar.gz \
  && cd orafce-VERSION_${ORAFACE_VERSION} \
  && make  --jobs=5 \
  && make  install --jobs=5    



RUN wget https://github.com/tada/pljava/archive/V${PL_JAVA_VERSION}.tar.gz -P /tmp/sources/pljava/ \
  && cd /tmp/sources/pljava/ \
  && tar -xvf V${PL_JAVA_VERSION}.tar.gz \
  && cd pljava-${PL_JAVA_VERSION} \
  && mvn  clean package \
  && java  -jar /tmp/sources/pljava/pljava-${PL_JAVA_VERSION}/pljava-packaging/target/pljava-pg17.jar


RUN wget http://www.unixodbc.org/unixODBC-${UNIX_ODBC_VERSION}.tar.gz -P /tmp/sources/unixodbc/ \
  && cd /tmp/sources/unixodbc/ \
  && tar -xvf unixODBC-${UNIX_ODBC_VERSION}.tar.gz \
  && cd unixODBC-${UNIX_ODBC_VERSION} \
  && ./configure  --prefix=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5


RUN wget https://github.com/postgresql-interfaces/psqlodbc/archive/refs/tags/REL-${POSTGRES_INTERFACES_VERSION}.tar.gz -P /tmp/sources/psqlodbc/ \
  && cd /tmp/sources/psqlodbc/ \
  && tar -xvf REL-${POSTGRES_INTERFACES_VERSION}.tar.gz \
  && cd psqlodbc-REL-${POSTGRES_INTERFACES_VERSION} \
  && autoreconf  --install \
  && ./configure  --prefix=/opt/bitnami/postgresql --with-libpq=/opt/bitnami/postgresql --with-unixodbc=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5  


RUN wget https://github.com/protocolbuffers/protobuf/archive/refs/tags/v${PROTOBUF_VERSION}.tar.gz -P /tmp/sources/protobuf/ \
  && cd /tmp/sources/protobuf/ \
  && tar -xvf v${PROTOBUF_VERSION}.tar.gz \
  && cd protobuf-${PROTOBUF_VERSION} \
  && ./autogen.sh \
  && ./configure  --prefix=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5  

RUN wget https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz -P /tmp/sources/protobuf-c \
  && cd /tmp/sources/protobuf-c \
  && tar -xvf protobuf-c-${PROTOBUF_C_VERSION}.tar.gz \
  && cd protobuf-c-${PROTOBUF_C_VERSION} \
  && PKG_CONFIG_PATH=/opt/bitnami/common/lib/pkgconfig ./configure  --prefix=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5  



RUN wget http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz -P /tmp/sources/postgis/ \
  && cd /tmp/sources/postgis/ \
  && tar -xvf postgis-${POSTGIS_VERSION}.tar.gz \
  && cd postgis-${POSTGIS_VERSION} \ 
  && PKG_CONFIG_PATH=/opt/bitnami/common/lib/pkgconfig:/opt/bitnami/postgresql/lib/pkgconfig ./configure  --prefix=/opt/bitnami/postgresql --with-pgconfig=/opt/bitnami/postgresql/bin/pg_config --with-geosconfig=/opt/bitnami/postgresql/bin/geos-config --with-projdir=/opt/bitnami/postgresql --with-gdalconfig=/opt/bitnami/postgresql/bin/gdal-config --with-jsondir=/opt/bitnami/postgresql --with-protobufdir=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5


RUN wget https://github.com/pgaudit/pgaudit/archive/${PGAUDIT_VERSION}.tar.gz -P /tmp/sources/pgaudit/ \
  && cd /tmp/sources/pgaudit/ \
  && tar -xvf ${PGAUDIT_VERSION}.tar.gz \
  && cd pgaudit-${PGAUDIT_VERSION} \
  && make  USE_PGXS=1 --jobs=5 \
  && make  USE_PGXS=1 install --jobs=5


RUN wget https://github.com/pgbackrest/pgbackrest/archive/release/${PG_BACKREST_VERSION}.tar.gz -P /tmp/sources/pgbackrest/ \
  && cd /tmp/sources/pgbackrest/ \
  && tar -xvf ${PG_BACKREST_VERSION}.tar.gz \
  && cd /tmp/sources/pgbackrest/pgbackrest-release-${PG_BACKREST_VERSION} \
  && meson  setup --prefix /opt/bitnami/postgresql --pkg-config-path /opt/bitnami/postgresql/lib/pkgconfig /tmp/sources/pgbackrest/pgbackrest-release-${PG_BACKREST_VERSION}/build \
  && cd build \
  && ninja \
  && ninja  install


RUN wget https://github.com/pgvector/pgvector/archive/refs/tags/v${PGVECTOR_VERSION}.tar.gz -P /tmp/sources/pgvector/ \
  && cd /tmp/sources/pgvector/ \
  && tar -xvf v${PGVECTOR_VERSION}.tar.gz \
  && cd pgvector-${PGVECTOR_VERSION} \
  && make  USE_PGXS=1 --jobs=5 \
  && make  USE_PGXS=1 install --jobs=5


RUN mkdir -p /tmp/sources/pg-failover-slots \
  && wget https://github.com/EnterpriseDB/pg_failover_slots/archive/refs/tags/v${PG_FAILOVER_VERSION}.tar.gz -P /tmp/sources/pg-failover-slots/ \
  && cd /tmp/sources/pg-failover-slots \
  && tar -xvf v${PG_FAILOVER_VERSION}.tar.gz \
  && cd pg_failover_slots-${PG_FAILOVER_VERSION} \
  && make  USE_PGXS=1 --jobs=5 \
  && make  USE_PGXS=1 install --jobs=5


RUN wget https://ftp.samba.org/pub/cwrap/nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz -P /tmp/sources/nss_wrapper/ \
  && cd /tmp/sources/nss_wrapper/ \
  && tar -xvf nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz \
  && cd nss_wrapper-${NSS_WRAPPER_VERSION} \
  && mkdir -v build \
  && cd build \
  && cmake .. -DCMAKE_INSTALL_PREFIX=/opt/bitnami/common \
  && make  --jobs=5 \
  && make  install --jobs=5
  

  

FROM oraclelinux:9-slim
ARG TARGETARCH
ARG EXTRA_LOCALES
ARG WITH_ALL_LOCALES="no"

LABEL org.opencontainers.image.base.name="docker.io/oraclelinux/oraclelinux:9-slim" \
      org.opencontainers.image.created="2025-05-20T13:37:50Z" \
      org.opencontainers.image.description="Application packaged by Aless Microsystems." \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/postgresql/README.md" \
      org.opencontainers.image.ref.name="17.5.0-ol9-ams" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/postgresql" \
      org.opencontainers.image.title="postgresql" \
      org.opencontainers.image.vendor="Aless Microsystems." \
      org.opencontainers.image.version="17.5.0"

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="ol9" \
    OS_NAME="linux"

COPY prebuildfs /
COPY --from=builder /opt/bitnami /opt/bitnami
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN microdnf update -y && microdnf install oracle-epel-release-el9 -y
RUN microdnf install -y \
  ca-certificates \
  curl \
  libbsd \
  bzip2-libs \
  libedit \
  libffi \
  libgcc \
  gmp \
  gnutls \
  nettle \
  libicu \
  libidn2 \
  openldap \
  lz4-libs \
  xz-libs \
  libmd \
  p11-kit \
  pcre \
  readline \
  cyrus-sasl-lib \
  sqlite \
  openssl \
  libstdc++ \
  libtasn1 \
  ncurses-libs \
  libunistring \
  libuuid \
  libxml2 \
  libxslt \
  libzstd \
  glibc-common \
  procps-ng \
  zlib \
  findutils \
  glibc-all-langpacks \
  glibc-utils \
  hostname

RUN groupadd -g 1001 alessmicro
RUN useradd -u 1001 -g alessmicro alessmicro
RUN chmod g+rwX /opt/bitnami
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

COPY rootfs /
RUN /opt/bitnami/scripts/postgresql/postunpack.sh
RUN chown -R alessmicro:alessmicro /opt/bitnami/postgresql/conf
RUN chown -R alessmicro:alessmicro /opt/bitnami/postgresql/tmp
RUN mkdir -vp /bitnami/postgresql/data
RUN chown -R alessmicro:alessmicro /bitnami/postgresql/data
#RUN /opt/bitnami/scripts/locales/add-extra-locales.sh
ENV APP_VERSION="17.5.0" \
    BITNAMI_APP_NAME="postgresql" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    LC_MESSAGES="POSIX" \
    NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
    PATH="/opt/bitnami/postgresql/bin:/opt/bitnami/common/bin:$PATH" 
#    LD_LIBRARY_PATH="/opt/bitnami/common/lib:/opt/bitnami/postgresql/lib:$LD_LIBRARY_PATH"

VOLUME [ "/bitnami/postgresql", "/docker-entrypoint-initdb.d", "/docker-entrypoint-preinitdb.d" ]

EXPOSE 5432

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
