FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    rust \
    cargo \
    openssl-dev \
    openssl-libs-static \
    pkgconf

ARG APP_VERSION

# Build i2pd-exporter (Static)
RUN wget "https://github.com/Jercik/i2pd-exporter/archive/refs/tags/${APP_VERSION}.tar.gz" -O app.tar.gz && \
    tar xvfz app.tar.gz && \
    cd i2pd-exporter-$(echo $APP_VERSION | sed 's/v//') && \
    # Compile statically
    OPENSSL_STATIC=1 cargo build --release && \
    strip target/release/i2pd-exporter && \
    cp target/release/i2pd-exporter /i2pd-exporter

# Final Stage
FROM alpine:latest
LABEL maintainer="JoanMorera"

# Install runtime dependencies
RUN apk add --no-cache ca-certificates libgcc

# Create user
RUN adduser -S -D -H -h /app exporter

# Copy artifacts
COPY --from=builder /i2pd-exporter /usr/bin/i2pd-exporter


USER exporter

ENTRYPOINT ["/usr/bin/i2pd-exporter"]
