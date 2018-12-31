FROM ubuntu:16.04

LABEL maintainer="dev@mirantis.com" MAINTENANCE_VERSION=2018-12-31

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LANG=C.UTF-8 \
    LANGUAGE=$LANG
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root
ARG UBUNTU_MIRROR_URL="http://archive.ubuntu.com/ubuntu"

COPY . /var/lib/cvp-spt/

WORKDIR /var/lib/
RUN set -ex; pushd /etc/apt/ && echo > sources.list && \
    echo 'Acquire::Languages "none";' > apt.conf.d/docker-no-languages && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > apt.conf.d/docker-gzip-indexes && \
    echo 'APT::Get::Install-Recommends "false"; APT::Get::Install-Suggests "false";' > apt.conf.d/docker-recommends && \
    echo "deb [arch=amd64] $UBUNTU_MIRROR_URL xenial main restricted universe multiverse" >> sources.list && \
    echo "deb [arch=amd64] $UBUNTU_MIRROR_URL xenial-updates main restricted universe multiverse" >> sources.list && \
    echo "deb [arch=amd64] $UBUNTU_MIRROR_URL xenial-backports main restricted universe multiverse" >> sources.list && \
    popd ; apt-get update && apt-get  upgrade -y && apt-get install -y python-pip git curl wget vim inetutils-ping && \
#Due to upstream bug we should use fixed version of pip
    python -m pip install --upgrade 'pip==9.0.3' && \
    pip install -r cvp-spt/requirements.txt && \
# Cleanup
    apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6 ppp pppconfig pppoeconf popularity-contest cpp gcc g++ libssl-doc && \
    apt-get -y autoremove; apt-get -y clean ; rm -rf /root/.cache; rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* ; rm -rf /var/tmp/*

ENTRYPOINT ["/bin/bash"]

# docker build --no-cache -t cvp-spt:test_latest
