FROM quay.io/rakuos/rakuos-gamescope-v3:staging

RUN rum install -y selinux-policy selinux-policy-targeted libselinux libselinux-utils policycoreutils policycoreutils-python-utils && \
    printf 'SELINUX=permissive\nSELINUXTYPE=targeted\n' > /etc/selinux/config && \
    mkdir -p /usr/lib/bootc/kargs.d && \
    printf 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=0", "apparmor=0"]\n' \
    > /usr/lib/bootc/kargs.d/90-security-overrides.toml

LABEL containers.bootc=1



