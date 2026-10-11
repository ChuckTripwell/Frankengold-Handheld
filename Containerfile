FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos



RUN curl -k -o /etc/pki/ca-trust/source/anchors/cacert.pem https://curl.se/ca/cacert.pem
RUN update-ca-trust


LABEL containers.bootc 1
RUN bootc -h
