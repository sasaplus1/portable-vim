#!/bin/bash

__main() {
  set -x
  set -euo pipefail

  local is_travis=$(bash -c '[ -n "$CI" ] && [ -n "$TRAVIS" ]; echo $?')

  if [ "$is_travis" -ne 0 ]
  then
    echo 'This script can execute in Travis-CI only.' >&2
    exit 1
  fi

  curl -fsSLO https://ftp.gnu.org/pub/gnu/gettext/gettext-${gettext_version}.tar.xz
  tar fvx ./gettext-${gettext_version}.tar.xz
  rm -f ./gettext-${gettext_version}.tar.xz

  (
    cd ./gettext-${gettext_version}
    ./configure \
      --prefix=${vim_prefix}/share/gettext \
      --disable-c++ \
      --disable-csharp \
      --disable-debug \
      --disable-dependency-tracking \
      --disable-java \
      --disable-silent-rules \
      --enable-relocatable \
      gl_cv_func_ftello_works=yes \
      --with-included-gettext \
      --with-included-glib \
      --with-included-libcroco \
      --with-included-libunistring \
      --without-bzip2 \
      --without-cvs \
      --without-emacs \
      --without-git \
      --without-xz
  )

  make -C ./gettext-${gettext_version}
  make -C ./gettext-${gettext_version} install
  rm -rf "${vim_prefix}/share/gettext/share/doc"
  tar cfJv ${archive} -C ${vim_prefix}/share gettext
}

__main "$@"

unset -f __main
