FROM jupyter/minimal-notebook

MAINTAINER Kozo Nishida <knishida@riken.jp>

USER root

RUN apt-get update && apt-get install -yq \
    libtool \
    pkg-config \
    autoconf \
    ruby \
    ruby-dev \
    rake \
    && apt-get clean && cd ~ && \
    git clone --depth=1 https://github.com/zeromq/libzmq && \
    git clone --depth=1 https://github.com/zeromq/czmq && \
    cd libzmq && ./autogen.sh && ./configure && make && make install && \
    cd ../czmq && ./autogen.sh && ./configure && make && make install && \
    gem install cztop specific_install && \
    gem specific_install https://github.com/SciRuby/iruby.git && \
    rm -rf /var/lib/apt/lists/* && ldconfig

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER

RUN iruby register
