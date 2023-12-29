FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04


# Select bash as default shell to prevent errors in "/.singularity.d/actions/shell":
RUN true \
    && echo "dash dash/sh boolean false" | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash


# User and workdir settings:

USER root
WORKDIR /root


# Install system packages:

RUN set -eux && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && sed -i 's/apt-get upgrade$/apt-get upgrade -y/' `which unminimize` \
    && (echo y | unminimize) \
	&& apt-get install -y --no-install-recommends ca-certificates \
    && apt-get install -y locales && locale-gen en_US.UTF-8 \
    && apt-get install -y \
        less \
        rsync \
        wget curl \
        nano vim \
        bzip2 \
        aptitude \
        \
        perl \
        \
        screen tmux parallel mc \
        util-linux numactl \
        \
        git \
        build-essential autoconf cmake pkg-config gfortran \
        libedit-dev libncurses-dev openssl libssl-dev symlinks \
        debhelper dh-autoreconf help2man libarchive-dev \
        squashfs-tools \
        \
    && apt-get install -y --no-install-recommends gnuplot \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install Nvidia visual profilers:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cuda-nsight-systems-12-1 cuda-nsight-12-1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Add CUDA libraries to LD_LIBRARY_PATH:

ENV \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/nvvm/lib64:$LD_LIBRARY_PATH" \
    JULIA_CUDA_USE_BINARYBUILDER="false"


# Copy provisioning script(s):

COPY provisioning/install-sw.sh /root/provisioning/


# Install Julia:

COPY provisioning/install-sw-scripts/julia-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/julia/bin:/opt/julia-1.10/bin:/opt/julia-1.9/bin:/opt/julia-1.6/bin:$PATH" \
    MANPATH="/opt/julia/share/man:$MANPATH"

RUN true\
    && provisioning/install-sw.sh julia-bindist 1.6.7 /opt/julia-1.6 \
    && (cd /opt/julia-1.6/bin && ln -s julia julia-1.6) \
    && provisioning/install-sw.sh julia-bindist 1.9.4 /opt/julia-1.9 \
    && (cd /opt/julia-1.9/bin && ln -s julia julia-1.9) \
    && provisioning/install-sw.sh julia-bindist 1.10.0 /opt/julia-1.10 \
    && (cd /opt/julia-1.10/bin && ln -s julia julia-1.10) \
    && (cd /opt && ln -s julia-1.10 julia)


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
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        fdupes libxdmcp6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && provisioning/install-sw.sh anaconda3 2023.07-1 /opt/anaconda3


# Install Jupyter extensions, jupytext and cffconvert, as well as other packages:

RUN true \
    && mamba install -c main -c conda-forge -y \
        jsonschema-with-format-nongpl webcolors \
    && mamba install -c main -c conda-forge -y \
        rise bash_kernel vega \
        css-html-js-minify \
        jupytext \
        jupyterlab-link-share \
        click docopt pykwalify ruamel.yaml \
    && pip3 install \
        cffconvert voila jupyter_contrib_nbextensions ipympl \
        "jupyterlab_rise<0.40.0" \
        webio_jupyter_extension juliacall \
    && mamba install -y mpi4py

    # css-html-js-minify required for Franklin.jl


# Install LaTeX (for Juypter PDF export and direct use):

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y \
        texlive texlive-latex-extra texlive-extra-utils texlive-science \
        texlive-fonts-extra texlive-bibtex-extra texlive-pstricks latexmk \
        biber feynmf latexdiff dvipng texlive-xetex pdf2svg cm-super \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install Node.js:

COPY provisioning/install-sw-scripts/nodejs-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/nodejs/bin:$PATH" \
    MANPATH="/opt/nodejs/share/man:$MANPATH"

RUN provisioning/install-sw.sh nodejs-bindist 20.9.0 /opt/nodejs


# Install Java:

# JavaCall.jl needs JAVA_HOME to locate libjvm.so:
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

RUN true \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update \
    && apt-get install -y openjdk-11-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install support for GUI applications:

RUN apt-get update && apt-get install -y \
        x11-xserver-utils mesa-utils \
        libglu1-mesa libegl1-mesa \
        xdg-utils \
        xvfb \
        libxss-dev libxtst-dev libxkbfile-dev \
        fonts-inconsolata fonts-dejavu \
        zenity \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install VirtualGL:

RUN apt-get update && apt-get install -y \
        libglu1-mesa libegl1-mesa \
    && wget \
        https://sourceforge.net/projects/virtualgl/files/3.1/virtualgl_3.1_amd64.deb \
        https://sourceforge.net/projects/turbovnc/files/3.0.3/turbovnc_3.0.3_amd64.deb \
    && dpkg -i virtualgl_3.1_amd64.deb turbovnc_3.0.3_amd64.deb \
    && rm virtualgl_3.1_amd64.deb turbovnc_3.0.3_amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Default profile environment settings:

ENV \
    LESSOPEN="||/usr/bin/lesspipe.sh %s"\
    LESSCLOSE=""


# Install additional packages:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        htop nmon \
        nano vim \
        git-gui gitk \
        ncat netcat \
        ncurses-term \
        parallel \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Final steps

CMD /bin/bash
