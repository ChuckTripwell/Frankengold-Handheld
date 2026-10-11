FROM quay.io/rakuos/rakuos-gamescope-v3:staging

##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################
# :::::: Fix SELinux :::::: 
#
RUN sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
#
RUN touch /etc/.autorelabel
#
RUN mkdir -p /usr/lib/bootc/kargs.d/
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system/selinux-autorelabel-mark.service
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/libexec/selinux/selinux-autorelabel
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh
RUN echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1", "apparmor=0"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml
#
RUN sed -i 's/active = yes/active = no/' /etc/audit/plugins.d/sedispatch.conf
#

LABEL containers.bootc=1
RUN bootc -h
