# https://github.com/lambci/docker-lambda#documentation
FROM lambci/lambda:build-provided
ARG RUST_VERSION
RUN yum install -y jq

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain $RUST_VERSION

# Build a static libpq library that we can link against

RUN echo "Building libpq" && \
    cd /tmp && \
    POSTGRESQL_VERSION=11.2 && \
    curl -LO "https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/postgresql-$POSTGRESQL_VERSION.tar.gz" && \
    tar xzf "postgresql-$POSTGRESQL_VERSION.tar.gz" && cd "postgresql-$POSTGRESQL_VERSION" && \
    ./configure --with-openssl --without-readline && \
    cd src/interfaces/libpq && make all-static-lib && make install-lib-static && \
    cd ../../bin/pg_config && make && make install && \
    rm -r /tmp/*

ENV PQ_LIB_STATIC_X86_64_UNKNOWN_LINUX_GNU=1 \
    PG_LIB_STATIC=1 \
    PG_LIB_DIR=/usr/local/pgsql/lib \
    PG_CONFIG_X86_64_UNKNOWN_LINUX_GNU=/usr/local/pgsql/bin/pg_config

ADD build.sh /usr/local/bin/
VOLUME ["/code"]
WORKDIR /code
ENTRYPOINT ["/usr/local/bin/build.sh"]
