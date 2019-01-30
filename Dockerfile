FROM postgres:11
ARG VERSION=8.1.1

LABEL maintainer="Citus Data https://citusdata.com" \
      org.label-schema.name="Citus" \
      org.label-schema.description="Scalable PostgreSQL for multi-tenant and real-time workloads" \
      org.label-schema.url="https://www.citusdata.com" \
      org.label-schema.vcs-url="https://github.com/citusdata/citus" \
      org.label-schema.vendor="Citus Data, Inc." \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV CITUS_VERSION ${VERSION}.citus-1
ARG DEBIAN_FRONTEND=noninteractive

#
# install postgis
#
# it's unclear why, but this must happen before Citus - in the other order, postgis fails to load
# PG_MAJOR from postgres docker base
ARG POSTGIS_MAJOR=2.5
ENV LANG en_ZA.UTF-8
ENV LANGUAGE en_ZA.UTF-8
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
                          postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
                          postgis-$POSTGIS_MAJOR \
       	       	       	  locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# en_ZA.UTF-8 UTF-8/en_ZA.UTF-8 UTF-8/' /etc/locale.gen \
    && echo 'LANG="en_ZA.UTF-8"'>/etc/default/locale \
    && dpkg-reconfigure locales \
    && update-locale LANG=en_ZA.UTF-8 \
    && dpkg-reconfigure locales \
    && rm -rf /var/lib/apt/lists/*

#
# install Citus
#
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-8.1=$CITUS_VERSION \
                          postgresql-$PG_MAJOR-hll=2.12.citus-1 \
                          postgresql-$PG_MAJOR-topn=2.2.0 \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# add citus to default PostgreSQL config
RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY 000-configure-stats.sh 001-create-citus-extension.sql 002-create-postgis-extension.sql /docker-entrypoint-initdb.d/

# add health check script
COPY pg_healthcheck /

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck
