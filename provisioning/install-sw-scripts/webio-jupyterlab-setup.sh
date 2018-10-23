# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2017: Oliver Schulz.


DEFAULT_BUILD_OPTS=""


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/share/jupyter/lab/staging/node_modules/julia-web-io/webio.js"
}


pkg_install() {
    GITHUB_USER=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 1`
    GIT_BRANCH=`echo "${PACKAGE_VERSION}" | cut -d '/' -f 2`
    git clone "https://github.com/${GITHUB_USER}/WebIO.jl" "WebIO.jl"
    cd "WebIO.jl"
    git checkout "${GIT_BRANCH}"

    export PATH="${INSTALL_PREFIX}/bin:${PATH}"
    cd "assets"
    jupyter labextension install webio
    jupyter labextension enable webio/jupyterlab_entry
}
