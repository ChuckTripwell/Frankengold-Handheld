FROM ghcr.io/ublue-os/bazzite-deck:latest AS base



RUN rm -rf /usr
COPY --from="quay.io/rakuos/rakuos-gamescope-v3:staging" /usr /usr


LABEL containers.bootc=1



