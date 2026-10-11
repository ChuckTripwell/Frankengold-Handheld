FROM quay.io/rakuos/rakuos-gamescope-v3:staging

RUN mkdir -p /usr/local/share/ca-certificates && \
    wget --no-check-certificate -O /usr/local/share/ca-certificates/cacert.pem https://curl.se/ca/cacert.pem

ENV CURL_CA_BUNDLE=/usr/local/share/ca-certificates/cacert.pem
ENV SSL_CERT_FILE=/usr/local/share/ca-certificates/cacert.pem

LABEL containers.bootc=1
RUN bootc -h
