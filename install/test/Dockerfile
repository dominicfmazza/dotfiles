# Test image for bootstrap.sh. A minimal host, with no root for the test user.
#
# The default base is RHEL 9 (UBI), because that matches the target fleet.
# UBI 9 ships zsh 5.8, which is the exact version floor in the README.
#
# Build and run through install/test/run.sh. That script also copies any
# corporate CA the host trusts into the image.
#
# The image holds only the hard requirements from the README:
# git, curl, tar, gzip, xz, unzip, zsh, and ca-certificates.
# It has no gcc, no libatomic, no stow, and no sudo. mise supplies the rest.

ARG BASE=registry.access.redhat.com/ubi9/ubi:latest
FROM ${BASE}

# One layer for both package managers, so DOTFILES_TEST_BASE can point at a
# Debian image as well. UBI 9 already ships curl-minimal, so the list must
# not name curl: the full package conflicts with the minimal one.
#
# The list holds ONLY the README host requirements. It has no libatomic and
# no compiler on purpose, so a test proves a plain rootless host works.
RUN set -eux; \
    if command -v dnf >/dev/null 2>&1; then \
    dnf -q -y install ca-certificates git gzip tar unzip xz zsh \
    glibc-langpack-en shadow-utils findutils; \
    dnf -q clean all; \
    else \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -qq; \
    apt-get install -y --no-install-recommends \
    ca-certificates curl git gzip tar unzip xz-utils zsh locales; \
    locale-gen en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/*; \
    fi

# Trust the CAs the host trusts. install/test/run.sh fills install/test/ca/
# from the host store. The directory always holds a .gitkeep file, so this
# layer stays valid when the host has no extra CA.
COPY install/test/ca/ /etc/pki/ca-trust/source/anchors/
RUN command -v update-ca-trust >/dev/null 2>&1 && update-ca-trust >/dev/null 2>&1 \
    || { cp -f /etc/pki/ca-trust/source/anchors/*.crt /usr/local/share/ca-certificates/ 2>/dev/null \
    && update-ca-certificates >/dev/null 2>&1; } \
    || true

RUN useradd -m -s /bin/bash tester
USER tester
WORKDIR /home/tester

ENV HOME=/home/tester \
    LANG=en_US.UTF-8 \
    TERM=xterm-256color \
    PATH=/home/tester/.local/bin:/usr/local/bin:/usr/bin:/bin

# The repo arrives as a copy, so a test never writes to the real checkout.
COPY --chown=tester:tester . /home/tester/dotfiles

WORKDIR /home/tester/dotfiles
CMD ["/bin/bash"]
