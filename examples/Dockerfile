FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    linux-headers \
    openssl-dev \
    openssl-libs-static \
    zlib-dev \
    zlib-static \
    boost-dev \
    boost-static \
    miniupnpc-dev \
    libatomic \
    samurai

ARG I2PD_VERSION
ARG TARGETARCH
ARG DEBUG_SYMBOLS=no

# Build Flags
ARG HARDENING_FLAGS="-O3 -fstack-clash-protection -Wformat -Werror=format-security -fno-plt -D_GLIBCXX_ASSERTIONS=1 -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_ENABLE_HARDENED_MODE=1 -flto"

# Build i2pd (Static + LTO + Hardening, no Mimalloc)
RUN wget "https://github.com/PurpleI2P/i2pd/archive/refs/tags/${I2PD_VERSION}.tar.gz" -O i2pd.tar.gz && \
    tar xvfz i2pd.tar.gz && \
    cd i2pd-$(echo $I2PD_VERSION | sed 's/v//') && \
    # Compile
    if [ "$DEBUG_SYMBOLS" = "yes" ]; then \
        make -j$(nproc) USE_UPNP=yes USE_STATIC=yes \
        CXXFLAGS="${HARDENING_FLAGS} -I/usr/include" \
        LDFLAGS="-static -flto -Wl,-z,relro -Wl,--gc-sections -L/usr/local/lib" \
        LDLIBS="-lboost_program_options -lboost_system -lboost_date_time -lboost_filesystem -lboost_thread -lboost_iostreams -lssl -lcrypto -lz -lminiupnpc -latomic" DEBUG=yes; \
    else \
        make -j$(nproc) USE_UPNP=yes USE_STATIC=yes \
        CXXFLAGS="${HARDENING_FLAGS} -I/usr/include" \
        LDFLAGS="-static -flto -Wl,-z,relro -Wl,--gc-sections -L/usr/local/lib" \
        LDLIBS="-lboost_program_options -lboost_system -lboost_date_time -lboost_filesystem -lboost_thread -lboost_iostreams -lssl -lcrypto -lz -lminiupnpc -latomic" && \
        strip i2pd; \
    fi && \
    cp i2pd /i2pd && \
    cp -r contrib/certificates /certificates

# Final Stage
FROM alpine:latest
LABEL maintainer="JoanMorera"

ENV I2PD_HOME="/home/i2pd"
ENV DATA_DIR="/home/i2pd/data"

# Create user and dirs
RUN adduser -S -h "$I2PD_HOME" -D i2pd && \
    mkdir -p "$DATA_DIR" && \
    mkdir -p /etc/i2pd && \
    chown -R i2pd:nobody "$I2PD_HOME" && \
    chown -R i2pd:nobody /etc/i2pd

# Copy i2pd artifacts
COPY --from=builder /i2pd /usr/bin/i2pd
COPY --from=builder /certificates /usr/share/i2pd/certificates
COPY i2pd-docker.conf /etc/i2pd/i2pd.conf
RUN chown i2pd:nobody /etc/i2pd/i2pd.conf

VOLUME "$DATA_DIR"
EXPOSE 7070 4444 4447 7656 2827 7654 7650
USER i2pd

ENTRYPOINT ["/usr/bin/i2pd"]
CMD ["--datadir=/home/i2pd/data"]