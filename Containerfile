FROM quay.io/rakuos/rakuos-gamescope-v3:staging

RUN rum install -y selinux-policy selinux-policy-targeted libselinux libselinux-utils policycoreutils policycoreutils-python-utils && \
    printf 'SELINUX=permissive\nSELINUXTYPE=targeted\n' > /etc/selinux/config && \
    mkdir -p /usr/lib/bootc/kargs.d && \
    printf 'kargs = ["selinux=1", "enforcing=0"]\n' > /usr/lib/bootc/kargs.d/90-selinux.toml

LABEL containers.bootc=1

RUN bootc container lint
