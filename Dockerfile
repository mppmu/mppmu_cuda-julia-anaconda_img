FROM nvidia/cuda:9.2-cudnn7-devel-centos7

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
    && dbus-uuidgen > /etc/machine-id


# Copy provisioning script(s):

COPY provisioning/install-sw.sh /root/provisioning/


# Install CMake:

COPY provisioning/install-sw-scripts/cmake-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/cmake/bin:$PATH" \
    MANPATH="/opt/cmake/share/man:$MANPATH"

RUN provisioning/install-sw.sh cmake 3.12.3 /opt/cmake


# Install Julia:

COPY provisioning/install-sw-scripts/julia-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/julia/bin:$PATH" \
    MANPATH="/opt/julia/share/man:$MANPATH"

RUN true\
    && yum install -y \
        which libedit-devel ncurses-devel openssl openssl-devel symlinks \
    && provisioning/install-sw.sh julia-bindist 1.0.2 /opt/julia


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


# Add CUDA libraries to LD_LIBRARY_PATH:

ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/nvvm/lib64:$LD_LIBRARY_PATH"

# Install NVIDIA libcuda and create driver mount directories:

COPY provisioning/install-sw-scripts/nvidia-* provisioning/install-sw-scripts/

RUN true \
    && mkdir -p /usr/local/nvidia /etc/OpenCL/vendors \
    && provisioning/install-sw.sh nvidia-libcuda 410.57 /usr/lib64

# Note: Installed libcuda.so.1 only acts as a kind of stub. To run GPU code,
# NVIDIA driver libs must be mounted in from host to "/usr/local/nvidia"
# (e.g. via nvidia-docker or manually). OpenCL icd directory
# "/etc/OpenCL/vendors" should be mounted in from host as well.


# Install Anaconda2:

COPY provisioning/install-sw-scripts/anaconda2-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/anaconda2/bin:$PATH" \
    MANPATH="/opt/anaconda2/share/man:$MANPATH" \
    JUPYTER=jupyter

    # JUPYTER environment variable used by IJulia to detect Jupyter installation

RUN true \
    && yum install -y \
        libXdmcp \
        texlive-collection-latexrecommended texlive-dvipng texlive-adjustbox texlive-upquote texlive-ulem \
    && provisioning/install-sw.sh anaconda2 5.3.0 /opt/anaconda2

# Override some system libraries with Anaconda versions when used from Julia,
# to resolve library version conflicts (ZMQ.jl, e.g., currently requires
# GLIBCXX_3.4.20, matplotlib needs CXXABI_1.3.9 and a more recent libz).
RUN true \
    && ln -s /opt/anaconda2/lib/libz.so.1* /opt/julia/lib/julia


# Install Node.js:

COPY provisioning/install-sw-scripts/nodejs-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/nodejs/bin:$PATH" \
    MANPATH="/opt/nodejs/share/man:$MANPATH"

RUN provisioning/install-sw.sh nodejs-bindist 8.12.0 /opt/nodejs


# Install Java:

# JavaCall.jl needs JAVA_HOME to locate libjvm.so:
ENV JAVA_HOME="/usr/lib/jvm/java"

RUN yum install -y \
        java-1.8.0-openjdk-devel


# Install HDF5:

COPY provisioning/install-sw-scripts/hdf5-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/hdf5/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/hdf5/lib:$LD_LIBRARY_PATH"

RUN provisioning/install-sw.sh hdf5-srcbuild 1.10.2 /opt/hdf5


# Install support for graphical applications:

RUN yum install -y \
    xorg-x11-server-utils mesa-dri-drivers glx-utils \
    xdg-utils \
    xorg-x11-server-Xvfb


# Default profile environment settings:

ENV \
    LESSOPEN="||/usr/bin/lesspipe.sh %s"\
    LESSCLOSE=""


# Clean up:

RUN true \
    && yum clean all


# Final steps

CMD /bin/bash
