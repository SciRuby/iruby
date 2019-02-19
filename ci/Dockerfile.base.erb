FROM rubylang/ruby:<%= ruby_version %>-bionic

ADD ci/requirements.txt /tmp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
               libczmq-dev \
               python3 \
               python3-pip \
               python3-setuptools \
               libpython3.6 \
    && pip3 install wheel \
    && pip3 install -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# ZeroMQ version 4.1.6 and CZMQ version 3.0.2 for rbczmq
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
               build-essential \
               file \
               wget \
    && cd /tmp \
    && wget https://github.com/zeromq/zeromq4-1/releases/download/v4.1.6/zeromq-4.1.6.tar.gz \
    && wget https://archive.org/download/zeromq_czmq_3.0.2/czmq-3.0.2.tar.gz \
    && tar xf zeromq-4.1.6.tar.gz \
    && tar xf czmq-3.0.2.tar.gz \
    && \
    ( \
        cd zeromq-4.1.6 \
        && ./configure \
        && make install \
    ) \
    && \
    ( \
        cd czmq-3.0.2 \
        && wget -O 1.patch https://github.com/zeromq/czmq/commit/2594d406d8ec6f54e54d7570d7febba10a6906b2.diff \
        && wget -O 2.patch https://github.com/zeromq/czmq/commit/b651cb479235751b22b8f9a822a2fc6bc1be01ab.diff \
        && cat *.patch | patch -p1 \
        && ./configure \
        && make install \
    )
