# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/node"
}


pkg_install() {
    PACKAGE_VERSION_MAJOR=`echo "${PACKAGE_VERSION}" | cut -f 1,2 -d . | grep -o '[0-9.]*'`

    DOWNLOAD_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-x64.tar.xz"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    mkdir -p "${INSTALL_PREFIX}"
    download "${DOWNLOAD_URL}" \
        | tar --strip-components=1 -x -J -f - -C "${INSTALL_PREFIX}"
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
MANPATH="${INSTALL_PREFIX}/share/man:\$MANPATH"
export PATH MANPATH
EOF
}
