FROM alpine:latest AS certs
RUN apk add --no-cache curl && \
    curl -o /tmp/cacert.pem https://curl.se/ca/cacert.pem

FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos
COPY --from=certs /tmp/cacert.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

LABEL containers.bootc=1
RUN bootc -h
