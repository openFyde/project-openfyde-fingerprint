# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson udev

DESCRIPTION="Library to add support for consumer fingerprint readers"
HOMEPAGE="https://cgit.freedesktop.org/libfprint/libfprint/ https://github.com/freedesktop/libfprint https://gitlab.freedesktop.org/libfprint/libfprint"
#SRC_URI="https://github.com/freedesktop/libfprint/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://gitlab.freedesktop.org/libfprint/libfprint/-/archive/v${PV}/libfprint-v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="2"
RESTRICT="mirror"
KEYWORDS="~alpha amd64 arm arm64 ~ia64 ~ppc ~ppc64 ~riscv ~sparc x86"
IUSE="examples gtk-doc +introspection test-utils"

RDEPEND="
	dev-libs/glib:2
	dev-libs/libgudev
	dev-libs/libgusb
	dev-libs/nss
	dev-libs/libusb
	x11-libs/pixman
	!>=sys-auth/libfprint-1.90:0
	examples? (
		x11-libs/gdk-pixbuf:2
		x11-libs/gtk+:3
	)
"

DEPEND="${RDEPEND}"

BDEPEND="
	virtual/pkgconfig
	gtk-doc? ( dev-util/gtk-doc )
	introspection? (
		dev-libs/gobject-introspection
		dev-libs/libgusb[introspection]
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-1.94.1-test-timeout.patch
  "${FILESDIR}"/001-add-fprint-info.patch
)

S="${S%/*}/libfprint-v${PV}"


create-cross-file() {
  CROSS_FILE=${T}/meson.${CHOST}.${ABI}
  cp ${FILESDIR}/cross.conf $CROSS_FILE
}

src_configure() {
  create-cross-file
	local emesonargs=(
		$(meson_use examples gtk-examples)
		$(meson_use gtk-doc doc)
		$(meson_use introspection)
		-Ddrivers=all
		-Dudev_rules=disabled
		-Dudev_rules_dir=$(get_udevdir)/rules.d
		--libdir=/usr/$(get_libdir)
    --cross-file=${CROSS_FILE}
	)
	meson_src_configure
}

src_install() {
  meson_src_install
  udev_dorules ${FILESDIR}/70-libfprint-2.rules
  exeinto /usr/bin
  build="${S%/*}/${P}-build"
  doexe ${build}/libfprint/fprint-list-supported-devices
  if use test-utils; then
    exeinto /usr/bin
    doexe ${build}/examples/{cpp-test,enroll,identify,img-capture,manage-prints,verify}
  fi
}
