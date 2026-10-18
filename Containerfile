FROM ___ AS build

RUN dnf5 -y install dnf5-plugins
RUN rpm --import https://repo.rakuos.org/pubkey.gpg
RUN dnf5 -y config-manager addrepo --from-repofile=https://repo.rakuos.org/rakuos.repo
RUN sed -i '/^\[rakuos-v3\]/,/^\[/ s/^enabled=0/enabled=1/' /etc/yum.repos.d/rakuos.repo

RUN dnf5 -y install rakuos-rum rum-dnf-shim



RUN REPO_OWNERS=$(rpm -qf --qf '%{NAME}\n' /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/*.repo 2>/dev/null | grep -v 'not owned' | sort -u || true)
RUN if [ -n "$REPO_OWNERS" ]; then ;    rum reinstall -y $REPO_OWNERS || echo "WARNING: couldn't reinstall $REPO_OWNERS; moving their repo files instead" ; fi
RUN mkdir -p /usr/share/rum/repos.d
RUN for repo in /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/*.repo; do ;    [ -e "$repo" ] || continue ;    mv -f "$repo" /usr/share/rum/repos.d/ ; done


RUN shipped_repo_files() { ; local dir ; for dir in /usr/share/rum/repos.d /etc/yum.repos.d /usr/share/dnf5/repos.d ; do ; ls $dir/$1 2>/dev/null || true ; done ; }

