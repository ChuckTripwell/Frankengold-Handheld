FROM quay.io/rakuos/rakuos-gamescope-v3:staging

RUN rum -y install \
  selinux-policy \
  selinux-policy-targeted \
  policycoreutils \
  policycoreutils-python-utils \
  libselinux-utils \
  setools-console \
  setroubleshoot-server \
  libselinux \
  audit

RUN printf 'SELINUX=permissive\nSELINUXTYPE=targeted\n' > /etc/selinux/config && \
    mkdir -p /usr/lib/bootc/kargs.d && \
    printf 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=0", "apparmor=0"]\n' \
    > /usr/lib/bootc/kargs.d/90-security-overrides.toml

RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' \
    /usr/sbin/fixfiles \
    /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh

LABEL containers.bootc=1



