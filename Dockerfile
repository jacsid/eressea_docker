# develop, master
ARG echeck_branch=master
ARG eressea_branch=develop

#-------------------------------------------------------------------------------
FROM debian:buster-slim as builder
RUN apt-get update && \
    apt-get install -y git gcc make gettext

#-------------------------------------------------------------------------------
# version 4.4.9 will not work in buster (segmentation fault)
FROM builder as echeck-master
RUN apt-get install -y curl && \
    curl -s https://packagecloud.io/install/repositories/enno/eressea/script.deb.sh | bash && \
    apt-get install echeck=4.4.9 && \
    mkdir -p /usr/share/locale/de/LC_MESSAGES

#-------------------------------------------------------------------------------
FROM builder as echeck-develop
RUN git clone -b master https://github.com/eressea/echeck.git git.echeck && \
    cd git.echeck && \
    mkdir -p /usr/share/locale/de/LC_MESSAGES && \
    make install

#-------------------------------------------------------------------------------
FROM echeck-${echeck_branch} as eressea-base
COPY docker-assets/check-orders.sh.patch /eressea/
RUN mkdir -p /eressea/server && \
    cd /eressea && \
    git clone -b master https://github.com/eressea/orders-php.git git.orders-php && \
    cd /eressea/git.orders-php && \
    patch check-orders.sh < /eressea/check-orders.sh.patch && \ 
    make install

#-------------------------------------------------------------------------------
FROM eressea-base as eressea
ARG eressea_branch
COPY docker-assets/backup-eressea.patch /eressea/
COPY docker-assets/create-orders.patch /eressea/
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    cmake luarocks libxml2-dev liblua5.2-dev libtolua-dev libncurses5-dev libsqlite3-dev \
    libexpat1-dev && \
    cd /eressea && \
    git clone -b $eressea_branch https://github.com/eressea/server.git git.eressea && \
    cd git.eressea && \
    git submodule update --init && \
    patch process/backup-eressea < /eressea/backup-eressea.patch && \
    s/cmake-init && \
    s/build && \
    ln -sf conf/eressea.ini && \
    s/install -f

#-------------------------------------------------------------------------------
FROM debian:buster-slim as final-image
ARG echeck_branch
ARG eressea_branch

LABEL version="eressea-${eressea_branch}.echeck-${echeck_branch}"
LABEL maintainer="juergen.holly@jacs.at"
LABEL description="Pbem Eressea"

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ERESSEA=/data
ENV PATH="${PATH}:/usr/games"

RUN apt-get update && \
    apt-get install -y liblua5.2-0 libsqlite3-0 libncurses5 libreadline7 libexpat1 python python-pip mutt nano \
    logrotate pwgen zip luarocks fetchmail procmail php7.3 gettext php7.3-sqlite && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install bcrypt j2cli && \
    apt-get autoremove -y && \
    sed --in-place '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    sed --in-place '/de_DE.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen

COPY docker-assets/template-config/ /eressea/template-config/
COPY docker-assets/lua-scripts/ /eressea/lua-scripts/
COPY docker-assets/run-eressea.sh /eressea/run-eressea.sh
COPY docker-assets/start.sh /eressea/start.sh
COPY --from=eressea /eressea/server/ /eressea/server/
COPY --from=eressea /eressea/git.eressea/scripts/tools /eressea/server/scripts/tools
COPY --from=eressea /eressea/git.eressea/s/preview /eressea/server/bin/
COPY --from=eressea /usr/games/echeck /usr/games/echeck
COPY --from=eressea /usr/share/locale/de/LC_MESSAGES/ /usr/share/locale/de/LC_MESSAGES/
COPY --from=eressea /usr/share/games/echeck/ /usr/share/games/echeck/
COPY --from=eressea /eressea/git.orders-php/ /eressea/orders-php/

VOLUME ["/data"]
WORKDIR /data
ENTRYPOINT ["/eressea/start.sh"]
CMD ["help"]
