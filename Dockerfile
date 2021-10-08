# global args
ARG __BUILD_DIR__="/build"
ARG __WORK_DIR__="/work"



FROM fscm/centos:stream as build

ARG __BUILD_DIR__
ARG __WORK_DIR__
ARG WHOIS_VERSION="5.5.10"
ARG __USER__="root"
ARG __SOURCE_DIR__="${__WORK_DIR__}/src"

ENV \
  LANG="C.UTF-8" \
  LC_ALL="C.UTF-8"

USER "${__USER__}"

COPY "LICENSE" "${__WORK_DIR__}"/

WORKDIR "${__WORK_DIR__}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
# build env
  echo '--> setting build env' && \
  set +h && \
  export __NPROC__="$(getconf _NPROCESSORS_ONLN || echo 1)" && \
  export DCACHE_LINESIZE="$(getconf LEVEL1_DCACHE_LINESIZE || echo 64)" && \
  export MAKEFLAGS="--silent --no-print-directory --jobs ${__NPROC__}" && \
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && \
# build structure
  echo '--> creating build structure' && \
  for folder in 'bin'; do \
    install --directory --owner="${__USER__}" --group="${__USER__}" --mode=0755 "${__BUILD_DIR__}/usr/${folder}"; \
  done && \
  for folder in '/tmp' "${__WORK_DIR__}"; do \
    install --directory --owner="${__USER__}" --group="${__USER__}" --mode=1777 "${__BUILD_DIR__}${folder}"; \
  done && \
# dependencies
  echo '--> instaling dependencies' && \
  dnf --assumeyes --quiet --setopt=install_weak_deps='no' install \
    binutils \
    ca-certificates \
    curl \
    diffutils \
    file \
    findutils \
    gcc \
    gettext \
    gzip \
    jq \
    make \
    perl-autodie \
    perl-interpreter \
    perl-open \
    rsync \
    tar \
    xz \
    > /dev/null && \
# musl
  echo '--> installing musl libc' && \
  install --directory "${__SOURCE_DIR__}/musl/_build" && \
  curl --silent --location --retry 3 "https://musl.libc.org/releases/musl-latest.tar.gz" \
    | tar xz --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/musl" && \
  cd "${__SOURCE_DIR__}/musl/_build" && \
  ../configure \
    CFLAGS="-O2 -g0 -s -w -pipe -mtune=generic -DNDEBUG -DCLS=${DCACHE_LINESIZE}" \
    --prefix='/usr/local' \
    --disable-debug \
    --disable-shared \
    --enable-wrapper=all \
    --enable-static \
    > /dev/null && \
  make > /dev/null && \
  make install > /dev/null && \
  cd ~- && \
  rm -rf "${__SOURCE_DIR__}/musl" && \
# libxcrypt
  echo '--> installing libxcrypt' && \
  install --directory "${__SOURCE_DIR__}/libxcrypt/_build" && \
  LIBXCRYPT_URL="$(curl --silent --location --retry 3 'https://api.github.com/repos/besser82/libxcrypt/releases/latest' \
    | jq -r '.assets[] | select(.content_type=="application/x-xz") | .browser_download_url')" && \
  curl --silent --location --retry 3 "${LIBXCRYPT_URL}" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/libxcrypt" && \
  cd "${__SOURCE_DIR__}/libxcrypt/_build" && \
  ../configure \
    CC="musl-gcc -static --static" \
    CFLAGS="-O2 -g0 -s -w -pipe -mtune=generic -DNDEBUG -DCLS=${DCACHE_LINESIZE}" \
    --quiet \
    --prefix='/usr/local' \
    --includedir='/usr/local/include' \
    --libdir='/usr/local/lib' \
    --sysconfdir='/etc' \
    --enable-fast-install \
    --enable-hashes='all' \
    --enable-obsolete-api='glibc' \
    --enable-silent-rules \
    --enable-static \
    --disable-failure-tokens \
    --disable-shared && \
  make > /dev/null && \
  make install > /dev/null && \
  cd ~- && \
  rm -rf "${__SOURCE_DIR__}/libxcrypt" && \
# whois (mkpasswd)
  echo '--> installing whois (mkpasswd)' && \
  install --directory "${__SOURCE_DIR__}/whois" && \
  curl --silent --location --retry 3 "https://github.com/rfc1036/whois/archive/v${WHOIS_VERSION}/whois-${WHOIS_VERSION}.tar.gz" \
    | tar xz --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/whois" && \
  cd "${__SOURCE_DIR__}/whois" && \
  make \
    CC="musl-gcc -static --static" \
    CFLAGS="-O2 -g0 -s -w -pipe -mtune=generic -DNDEBUG -DCLS=${DCACHE_LINESIZE} -DHAVE_GETOPT_LONG" \
    mkpasswd \
    > /dev/null && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" './mkpasswd' && \
  install --directory --owner="${__USER__}" --group="${__USER__}" --mode=0755 "${__BUILD_DIR__}/licenses/whois" && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0644 --target-directory="${__BUILD_DIR__}/licenses/whois" './COPYING' && \
  cd ~- && \
  rm -rf "${__SOURCE_DIR__}/whois" && \
# stripping
  echo '--> stripping binaries' && \
  find "${__BUILD_DIR__}"/usr/bin -type f -not -links +1 -exec strip --strip-all {} ';' && \
# licenses
  echo '--> project licenses' && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0644 --target-directory="${__BUILD_DIR__}/licenses" "${__WORK_DIR__}/LICENSE" && \
# done
  echo '--> all done!'



FROM scratch

ARG __BUILD_DIR__
ARG __WORK_DIR__

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>" \
  vendor="fscm" \
  cmd="docker container run --detach --publish 53:53/udp fscm/mkpasswd" \
  params="--volume ./:${__WORK_DIR__}:rw"

COPY --from=build "${__BUILD_DIR__}" "/"

VOLUME ["${__WORK_DIR__}"]

WORKDIR "${__WORK_DIR__}"

ENTRYPOINT ["/usr/bin/mkpasswd"]

#CMD ["--help"]