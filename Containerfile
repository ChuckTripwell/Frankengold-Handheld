ARG KERNEL_NAME=linux-cachyos-deckify


FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

RUN pacman -Sy --noconfirm $KERNEL_NAME



FROM ghcr.io/ublue-os/bazzite-deck:stable

RUN rm -rf /lib/modules/*
COPY --from="cachyos" /lib/modules/* /lib/modules/

RUN bootc container lint
