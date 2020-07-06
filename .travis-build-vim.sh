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

  git config --global user.name sasaplus1
  git config --global user.email '<>'

  git clone --depth 1 https://github.com/koron/guilt.git
  git clone --depth 1 https://github.com/koron/vim-kaoriya.git

  (
    cd vim-kaoriya
    git submodule update --depth 1 --init --recommend-shallow --recursive -- ./contrib/vimdoc-ja ./patches ./vim
    export vim_version=$(printf -- '%b' 'all:\n\t@printf -- $(VIM_VER)' | make -f VERSION -f -)
  )

  gsed -i.bak -r -e 's|\<readlink\>|greadlink|g' ./guilt/guilt
  make -C ./guilt PREFIX=/usr/local install

  (
    cd vim-kaoriya/vim
    git checkout -b v${vim_version}
    git config --local guilt.patchesdir ../patches
    guilt init
  )

  (
    cd vim-kaoriya
    cp ./patches/master/* "./patches/v${vim_version}"
  )

  (
    cd vim-kaoriya/vim/src
    guilt push --all
  )

  mkdir -p "${sharedir}"
  tar xvf gettext-macos-${macos_version}.tar.xz -C "${sharedir}"
  export PATH=$gettext/bin:$PATH
  make -C ./vim-kaoriya/vim/src autoconf

  (
    cd vim-kaoriya/vim
    export LUA_PREFIX="$(brew --prefix)"
    export CFLAGS="-I${gettext}/include"
    export LDFLAGS="-L${gettext}/lib"
    eval "./configure --prefix=${prefix} ${configurations}"
    make DATADIR=${datadir}
    make install
  )

  gsed -i.bak -r -e "s|\<root\>|$(whoami)|g" ./vim-kaoriya/build/freebsd/Makefile
  make -C ./vim-kaoriya/build/freebsd VIM_DIR="${sharedir}/vim" kaoriya-install
  cp -rf vim-kaoriya/contrib/vimdoc-ja "${sharedir}/vim/plugins"
  cp ./portable-vim "${prefix}/bin"

  (
    cd "${prefix}/bin"
    ln -s portable-vim pex
    ln -s portable-vim pview
    ln -s portable-vim pvimdiff
    ln -s portable-vim rpview
    ln -s portable-vim rpvim
  )

  install_name_tool \
    -change \
    "$(otool -L ${prefix}/bin/vim | awk '/libintl/ { print $1 }')" \
    '@executable_path/../share/gettext/lib/libintl.dylib' \
    "${prefix}/bin/vim"

  otool -L "${prefix}/bin/vim"
  "${prefix}/bin/vim" --version

  tar cfJv "vim-${vim_version}-macos-${macos_version}.tar.xz" -C "${prefix}/.." vim
  shasum -a 256 -b "vim-${vim_version}-macos-${macos_version}.tar.xz" | tee sha256sum.txt
}

__main "$@"

unset -f __main
