FROM ghcr.io/ublue-os/bazzite-deck:stable AS salvage
FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos


RUN rm -rf /etc
COPY --from=salvage /etc /etc


LABEL containers.bootc 1
RUN bootc container lint
