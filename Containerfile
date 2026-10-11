FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos


RUN dnf install -y ca-certificates && update-ca-trust extract


LABEL containers.bootc 1
RUN bootc -h
