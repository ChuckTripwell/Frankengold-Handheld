FROM alpine:latest AS certs
RUN apk add --no-cache ca-certificates && \
    update-ca-trust

FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos

# Copy the extracted bundle directly into the path libcurl checks
COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

LABEL containers.bootc=1
RUN bootc -h
