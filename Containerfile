FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS base

#RUN rum -y install \
#  selinux-policy \
#  selinux-policy-targeted \
#  policycoreutils \
#  policycoreutils-python-utils \
#  libselinux-utils \
#  setools-console \
#  setroubleshoot-server \
#  libselinux \
#  audit

RUN printf 'SELINUX=permissive\nSELINUXTYPE=targeted\n' > /etc/selinux/config && \
    mkdir -p /usr/lib/bootc/kargs.d && \
    printf 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "apparmor=0"]\n' \
    > /usr/lib/bootc/kargs.d/90-security-overrides.toml




# :::::: Fix SELinux :::::: 
#
RUN sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
#
RUN touch /etc/.autorelabel
#
RUN mkdir -p /usr/lib/bootc/kargs.d/
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/sbin/fixfiles
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system/selinux-autorelabel-mark.service
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/libexec/selinux/selinux-autorelabel
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh
RUN echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml
#
RUN sed -i 's/active = yes/active = no/' /etc/audit/plugins.d/sedispatch.conf

FROM scratch AS build

RUN mkdir -p /system_build
COPY --from="quay.io/bootc-devel/fedora-bootc-rawhide-compose:latest" / /system_build/
RUN rm -rf /boot/* /usr/lib/modules/* /lib/modules/*
COPY --from="base" / /system_build/

FROM scratch AS final
COPY --from="build" /system_build/* /

LABEL containers.bootc=1



