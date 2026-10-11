FROM ghcr.io/ublue-os/bazzite-deck:stable AS salvage
FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos


COPY --from=salvage /etc/pki /etc/pki


LABEL containers.bootc 1
RUN bootc -h
