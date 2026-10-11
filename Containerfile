FROM quay.io/rakuos/rakuos-gamescope-v3:staging

#####################################################################################################################################################
# :::::: Security and Finalization :::::: #
#####################################################################################################################################################

# :::::: Fix SELinux :::::: #

RUN dnf -y install \
    selinux-policy \
    selinux-policy-targeted \
    policycoreutils \
    libselinux-utils && \
    dnf clean all

RUN mkdir -p /etc/selinux && \
    echo "SELINUX=enforcing" > /etc/selinux/config && \
    echo "SELINUXTYPE=targeted" >> /etc/selinux/config


#RUN mkdir -p /usr/lib/bootc/kargs.d/ && \
#    echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1", "apparmor=0"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml

LABEL containers.bootc=1

RUN bootc -h
