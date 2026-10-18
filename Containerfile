FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS base


FROM base AS build
RUN rm -rf /usr
COPY --from="ghcr.io/ublue-os/bazzite-deck:latest" /usr /usr

LABEL containers.bootc=1



