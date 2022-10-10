# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="7"

inherit toolchain-funcs

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="test-utils"

RDEPEND=""

DEPEND="${RDEPEND}"

S=$WORKDIR

S_DIR=${FILESDIR}/arm

src_configure() {
  use arm64 && S_DIR=${S_DIR}64
}

src_compile() {
  if ! use test-utils; then
    return
  fi
  tc-export AR CC NM OBJCOPY RANLIB
  ext_flags="-L${S_DIR} -lmafp -I${FILESDIR}/include"
  $CC $ext_flags $CFLAGS ${FILESDIR}/test-utils/mafpd.c -o $S/mafpd
}

src_install() {
  dolib.so ${S_DIR}/*.so
  insinto /usr/$(get_libdir)/pkgconfig
  doins ${S_DIR}/pkgconfig/libmafp.pc
  insinto /usr/include
  doins ${FILESDIR}/include/mafp_interfaces.h
  if use test-utils; then
    dobin mafpd
  fi
}
