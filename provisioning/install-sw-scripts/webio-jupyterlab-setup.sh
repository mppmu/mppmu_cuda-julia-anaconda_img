# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2017: Oliver Schulz.


DEFAULT_BUILD_OPTS=""


pkg_installed_check() {
    test -d "${INSTALL_PREFIX}/assets"
}


pkg_install() {
    GITHUB_USER=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 1`
    GIT_BRANCH=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 2`
    git clone "https://github.com/${GITHUB_USER}/WebIO.jl" "WebIO.jl"
    cd "WebIO.jl"
    git checkout "${GIT_BRANCH}"

    export PATH="${INSTALL_PREFIX}/bin:${PATH}"

    mkdir "${INSTALL_PREFIX}"
    cp -a "assets" "${INSTALL_PREFIX}/assets"
    cd "${INSTALL_PREFIX}/assets"
    jupyter labextension install webio
    jupyter labextension enable webio/jupyterlab_entry
}
