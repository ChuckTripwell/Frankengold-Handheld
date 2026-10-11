FROM quay.io/rakuos/rakuos-gamescope-v3:staging

#####################################################################################################################################################
# :::::: Security and Finalization :::::: #
#####################################################################################################################################################

# :::::: Fix SELinux :::::: #

# Install audit so that sedispatch.conf is present for modification
RUN dnf install -y audit && \
    sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system/selinux-autorelabel-mark.service && \
    sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/libexec/selinux/selinux-autorelabel && \
    sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh

RUN mkdir -p /usr/lib/bootc/kargs.d/ && \
    echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1", "apparmor=0"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml

RUN sed -i 's/active = yes/active = no/' /etc/audit/plugins.d/sedispatch.conf

LABEL containers.bootc=1

RUN bootc -h
