FROM centos:7

# User and workdir settings:

USER root
WORKDIR /root


# Install yum/RPM packages:

COPY provisioning/wandisco-centos7-git.repo /etc/yum.repos.d/wandisco-git.repo

RUN true \
    && sed -i '/tsflags=nodocs/d' /etc/yum.conf \
    && yum install -y \
        epel-release \
    && yum groupinstall -y \
        "Development Tools" \
    && yum install -y \
        wget curl rsync \
        p7zip \
        git svn \
        lsb-core-noarch \
        numactl \
    && dbus-uuidgen > /etc/machine-id


# Copy provisioning script(s):

COPY provisioning/install-sw.sh /root/provisioning/


# Install CMake:

COPY provisioning/install-sw-scripts/cmake-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/cmake/bin:$PATH" \
    MANPATH="/opt/cmake/share/man:$MANPATH"

RUN provisioning/install-sw.sh cmake 3.16.3 /opt/cmake


# Install Julia:

COPY provisioning/install-sw-scripts/julia-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/julia/bin:/opt/julia-1.3/bin:/opt/julia-1.0/bin:$PATH" \
    MANPATH="/opt/julia/share/man:$MANPATH"

RUN true\
    && yum install -y \
        which libedit-devel ncurses-devel openssl openssl-devel symlinks \
    && provisioning/install-sw.sh julia-bindist 1.0.5 /opt/julia-1.0 \
    && (cd /opt/julia-1.0/bin && ln -s julia julia-1.0) \
    && provisioning/install-sw.sh julia-bindist 1.3.1 /opt/julia-1.3 \
    && (cd /opt/julia-1.3/bin && ln -s julia julia-1.3) \
    && (cd /opt && ln -s julia-1.3 julia)


# Install depencencies of common Julia packages:

RUN true \
    && yum install -y \
        libgfortran4 \
        ImageMagick zeromq-devel \
        libXt libXrender libXext mesa-libGL \
        gtk2 gtk3 qt5-qtbase-gui glfw libxkbcommon-x11 \
        gsl-devel fftw-devel unixODBC


# Install ffmpeg (for Plots.jl animations, Makie.jl, etc.):

RUN true \
    && rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro \
    && rpm -ivh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm \
    && yum install -y ffmpeg ffmpeg-devel


# Install Anaconda3:

COPY provisioning/install-sw-scripts/anaconda3-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/anaconda3/bin:$PATH" \
    MANPATH="/opt/anaconda3/share/man:$MANPATH" \
    JUPYTER=jupyter

    # JUPYTER environment variable used by IJulia to detect Jupyter installation

RUN true \
    && yum install -y \
        fdupes \
        libXdmcp \
        texlive-collection-latexrecommended texlive-dvipng texlive-adjustbox texlive-upquote \
        texlive-ulem texlive-xetex inkscape \
    && provisioning/install-sw.sh anaconda3 2019.10 /opt/anaconda3

# Override some system libraries with Anaconda versions when used from Julia,
# to resolve library version conflicts (ZMQ.jl, e.g., currently requires
# GLIBCXX_3.4.20, matplotlib needs CXXABI_1.3.9 and a more recent libz).
# Not required for Julia >=v1.3.0-rc4 (brings it's own libz).
RUN true \
    && ln -s /opt/anaconda3/lib/libz.so.1* /opt/julia-1.0/lib/julia


# Install Jupyter extensions:

RUN true \
    && conda install -y -c conda-forge rise \
    && conda install -y -c conda-forge jupyter_contrib_nbextensions \
    && pip install bash_kernel && JUPYTER_DATA_DIR="/opt/anaconda3/share/jupyter" python -m bash_kernel.install


# Install Node.js:

COPY provisioning/install-sw-scripts/nodejs-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/nodejs/bin:$PATH" \
    MANPATH="/opt/nodejs/share/man:$MANPATH"

RUN provisioning/install-sw.sh nodejs-bindist 12.13.1 /opt/nodejs


# Install Java:

# JavaCall.jl needs JAVA_HOME to locate libjvm.so:
ENV JAVA_HOME="/usr/lib/jvm/java"

RUN yum install -y \
        java-1.8.0-openjdk-devel


# Install support for GUI applications:

RUN yum install -y \
    xorg-x11-server-utils mesa-dri-drivers glx-utils \
    xdg-utils \
    xorg-x11-server-Xvfb \
    libXScrnSaver libXtst libxkbfile \
    levien-inconsolata-fonts dejavu-sans-fonts


# Default profile environment settings:

ENV \
    LESSOPEN="||/usr/bin/lesspipe.sh %s"\
    LESSCLOSE=""


# Install additional packages:

RUN yum install -y \
        \
        htop nmon \
        nano vim \
        git-gui gitk \
        nmap-ncat \
        \
        http://linuxsoft.cern.ch/cern/centos/7/cern/x86_64/Packages/parallel-20150522-1.el7.cern.noarch.rpm


# Clean up:

RUN true \
    && yum clean all


# Final steps

CMD /bin/bash
