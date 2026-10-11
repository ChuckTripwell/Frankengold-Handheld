#FROM ghcr.io/ublue-os/bazzite-deck:stable AS salvage
FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS rakuos


RUN rum -y reinstall ca-certificates


LABEL containers.bootc 1
RUN bootc -h
