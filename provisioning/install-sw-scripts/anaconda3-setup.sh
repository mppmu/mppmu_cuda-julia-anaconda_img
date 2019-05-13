# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/conda"
}


pkg_install() {
    DOWNLOAD_URL="https://repo.continuum.io/archive/Anaconda3-${PACKAGE_VERSION}-Linux-x86_64.sh"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    download "${DOWNLOAD_URL}" > anaconda-installer.sh
    bash ./anaconda-installer.sh -b -p "${INSTALL_PREFIX}"

    conda clean -y --tarballs

    (
        cd "${INSTALL_PREFIX}"

        primary=""
        fdupes -H pkgs/*/lib lib | while read filename; do
            if [ -z "${filename}" ] ; then
                primary=""
            else
                if [ -z "${primary}" ] ; then
                    #echo
                    primary="../${filename}"
                    #echo PRIMARY=$primary
                else
                    echo "Replacing \"${filename}\" by symlink to \"${primary}\"" >&2
                    ln -s -f "${primary}" "${filename}"
                fi
            fi
        done
    )
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
MANPATH="${INSTALL_PREFIX}/share/man:\$MANPATH"
EOF
}
