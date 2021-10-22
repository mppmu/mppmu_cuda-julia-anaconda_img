FROM nvidia/cuda:11.3.0-cudnn8-devel-centos7


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
    PATH="/opt/julia/bin:/opt/julia-1.7/bin:/opt/julia/bin:/opt/julia-1.6/bin:/opt/julia-1.3/bin:/opt/julia-1.0/bin:$PATH" \
    MANPATH="/opt/julia/share/man:$MANPATH"

RUN true\
    && yum install -y \
        which libedit-devel ncurses-devel openssl openssl-devel symlinks \
    && provisioning/install-sw.sh julia-bindist 1.0.5 /opt/julia-1.0 \
    && (cd /opt/julia-1.0/bin && ln -s julia julia-1.0) \
    && provisioning/install-sw.sh julia-bindist 1.3.1 /opt/julia-1.3 \
    && (cd /opt/julia-1.3/bin && ln -s julia julia-1.3) \
    && provisioning/install-sw.sh julia-bindist 1.6.3 /opt/julia-1.6 \
    && (cd /opt/julia-1.6/bin && ln -s julia julia-1.6) \
    && provisioning/install-sw.sh julia-bindist 1.7.0-rc1 /opt/julia-1.7 \
    && (cd /opt/julia-1.7/bin && ln -s julia julia-1.7) \
    && (cd /opt && ln -s julia-1.7 julia)


# Install depencencies of common Julia packages:

RUN true \
    && yum install -y \
        gnuplot


# Add CUDA libraries to LD_LIBRARY_PATH:

ENV \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/nvvm/lib64:$LD_LIBRARY_PATH" \
    JULIA_CUDA_USE_BINARYBUILDER="false"


# Install Nvidia visual profiler:

RUN yum install -y cuda-nvvp-11-3 cuda-nsight-11-3


# Install Anaconda3 and Mamba:

COPY provisioning/install-sw-scripts/anaconda3-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/anaconda3/bin:/opt/anaconda3/condabin:$PATH" \
    MANPATH="/opt/anaconda3/share/man:$MANPATH" \
    CONDA_EXE="/opt/anaconda3/bin/conda" \
    CONDA_PREFIX="/opt/anaconda3" \
    CONDA_PYTHON_EXE="/opt/anaconda3/bin/python" \
    PYTHON="python3" \
    JUPYTER="jupyter"

    # PYTHON and JUPYTER environment variables for PyCall.jl and IJulia.jl

RUN true \
    && yum install -y \
        fdupes \
        libXdmcp \
    && provisioning/install-sw.sh anaconda3 2021.05 /opt/anaconda3


# Override some system libraries with Anaconda versions when used from Julia,
# to resolve library version conflicts (ZMQ.jl, e.g., currently requires
# GLIBCXX_3.4.20, matplotlib needs CXXABI_1.3.9 and a more recent libz).
# Not required for Julia >=v1.3.0-rc4 (brings it's own libz).
RUN true \
    && ln -s /opt/anaconda3/lib/libz.so.1* /opt/julia-1.0/lib/julia


# Install Jupyter extensions, jupytext, code-server and cffconvert:

RUN true \
    && mamba install -y -c conda-forge \
        rise jupyter_contrib_nbextensions bash_kernel vega \
        css-html-js-minify \
        jupyter-server-proxy jupytext \
        code-server \
    && mamba install -c conda-forge click docopt pykwalify ruamel.yaml && pip3 install cffconvert \
    && mamba install -y matplotlib=3.4 \
    && pip3 install webio_jupyter_extension


# css-html-js-minify required for Franklin.jl


# Install LaTeX (for Juypter PDF export and direct use):
RUN yum install -y texlive-collection-latexrecommended texlive-dvipng texlive-adjustbox \
    texlive-upquote texlive-ulem texlive-xetex texlive-epstopdf inkscape


# Install Node.js:

COPY provisioning/install-sw-scripts/nodejs-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/nodejs/bin:$PATH" \
    MANPATH="/opt/nodejs/share/man:$MANPATH"

RUN provisioning/install-sw.sh nodejs-bindist 14.18.1 /opt/nodejs


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
    levien-inconsolata-fonts dejavu-sans-fonts \
    zenity


# Install VirtualGL:

RUN yum install -y \
    https://sourceforge.net/projects/virtualgl/files/2.6.5/VirtualGL-2.6.5.x86_64.rpm \
    https://sourceforge.net/projects/virtualgl/files/2.6.5/VirtualGL-debuginfo-2.6.5.x86_64.rpm \
    https://sourceforge.net/projects/turbovnc/files/2.2.6/turbovnc-2.2.6.x86_64.rpm \
    https://sourceforge.net/projects/turbovnc/files/2.2.6/turbovnc-debuginfo-2.2.6.i386.rpm


# Install Visual Studio Code Live Share dependencies:

RUN wget -O ~/vsls-reqs https://aka.ms/vsls-linux-prereq-script && chmod +x ~/vsls-reqs && ~/vsls-reqs
# See https://docs.microsoft.com/en-us/visualstudio/liveshare/reference/linux#details-on-required-libraries


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
        ncurses-term \
        \
        http://linuxsoft.cern.ch/cern/centos/7/cern/x86_64/Packages/parallel-20150522-1.el7.cern.noarch.rpm


# Clean up:

RUN true \
    && yum clean all


# Final steps

CMD /bin/bash
