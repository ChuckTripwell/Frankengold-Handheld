FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos


RUN mkdir -p /etc/pki/ca-trust/source/anchors && \
    curl -k -o /etc/pki/ca-trust/source/anchors/cacert.pem https://curl.se/ca/cacert.pem && \
    update-ca-trust


LABEL containers.bootc 1
RUN bootc -h
