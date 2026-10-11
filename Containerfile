FROM quay.io/rakuos/rakuos-gamescope-v3:staging

#####################################################################################################################################################
# :::::: Security and Finalization :::::: #
#####################################################################################################################################################

# :::::: Fix SELinux :::::: #

RUN rum rm -y apparmor-devel apparmor-libs apparmor-parser apparmor-profiles apparmor-utils mod_apparmor pam_apparmor python3-apparmor python3-LibAppArmor

#COPY --from="quay.io/fedora/fedora:latest" /etc/dnf/protected.d/selinux-policy-targeted.conf /etc/dnf/protected.d/selinux-policy-targeted.conf
RUN rum install -y 'selinux-policy*' 'policycoreutils-gui'

RUN mkdir -p /usr/lib/bootc/kargs.d/ && \
    echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1", "apparmor=0, security="selinux" ]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml

RUN rum -y clean all

LABEL containers.bootc=1

RUN bootc -h
