# Copyright 2016 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="67d76a6fbdfa5d6c76e645d964b3167efc69d2e5"
CROS_WORKON_TREE=("b34cd17a5119e65123516e3d20992ce4b303fa5b" "a6c7a1d2d024085abf43d41bae4f44d24434e2f1" "e1670be578a26c9a520a82a3397b50c69c249dcf" "b0b3d80bdf56327ab7b473b6fe61a697716d28d3" "9f6f122db8b96d8fc6a6b026d0d1c66da21f79c1" "9050d91be8a513b5b9706395d3ed06adf219cf3e" "1a0387c9b012cec6f920128725766de73b934731" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_WORKON_USE_VCSID="1"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk biod chromeos-config libec libhwsec libhwsec-foundation metrics .gn"

PLATFORM_SUBDIR="biod"

inherit cros-fuzzer cros-sanitizers cros-workon cros-unibuild platform \
	cros-protobuf tmpfiles udev user

DESCRIPTION="Biometrics Daemon for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/biod/README.md"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="
	factory_branch
	fp_on_power_button
	fpmcu_firmware_bloonchipper
	fpmcu_firmware_buccaneer
	fpmcu_firmware_dartmonkey
	fpmcu_firmware_helipilot
	fpmcu_firmware_nami
	fpmcu_firmware_nocturne
	fuzzer
	test
  libfprint
  mafp
"
# We must depend on libusb because libec headers make use of libusb.
COMMON_DEPEND="
	chromeos-base/chromeos-config-tools:=
	chromeos-base/libec:=
	chromeos-base/libhwsec:=[test?]
	chromeos-base/libhwsec-foundation:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	chromeos-base/vboot_reference:=
	sys-apps/flashmap:=
	virtual/libusb:1=
"

# For biod_client_tool. The biod_proxy library will be built on all boards but
# biod_client_tool will be built only on boards with biod.
COMMON_DEPEND+="
	chromeos-base/biod_proxy:=
"

# The crosec-legacy-drv package is a pinned version of flashrom
# for production firmware updates.
RDEPEND="
	${COMMON_DEPEND}
	sys-apps/crosec-legacy-drv:=
	!factory_branch? ( virtual/chromeos-firmware-fpmcu )
	"

# Release branch firmware.
# The USE flags below come from USE_EXPAND variables.
# See third_party/chromiumos-overlay/profiles/base/make.defaults.
RDEPEND+="
	!factory_branch? (
		fpmcu_firmware_bloonchipper? (
			sys-firmware/chromeos-fpmcu-release-bloonchipper
			sys-firmware/chromeos-zephyr-fpmcu-release-bloonchipper
		)
		fpmcu_firmware_buccaneer? ( sys-firmware/chromeos-fpmcu-release-buccaneer )
		fpmcu_firmware_dartmonkey? ( sys-firmware/chromeos-fpmcu-release-dartmonkey )
		fpmcu_firmware_helipilot? ( sys-firmware/chromeos-fpmcu-release-helipilot )
		fpmcu_firmware_nami? ( sys-firmware/chromeos-fpmcu-release-nami )
		fpmcu_firmware_nocturne? ( sys-firmware/chromeos-fpmcu-release-nocturne )
	)
  libfprint? (
      dev-libs/glib
      sys-auth/libfprint
    )
  mafp? ( sys-auth/libmafp )
"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/chromeos-ec-headers:=
	chromeos-base/power_manager-client:=
	chromeos-base/system_api:=[fuzzer?]
	dev-libs/openssl:=
"

BDEPEND="
	chromeos-base/minijail
"

pkg_setup() {
	enewuser biod
	enewgroup biod
	enewgroup fpdev
}

src_install() {
	platform_src_install

	udev_dorules udev/99-biod.rules

	dotmpfiles tmpfiles.d/*.conf

	# Set up cryptohome daemon mount store in daemon's mount
	# namespace.
	local daemon_store="/etc/daemon-store/biod"
	dodir "${daemon_store}"
	fperms 0700 "${daemon_store}"
	fowners biod:biod "${daemon_store}"

	local fuzzer_component_id="782045"
	platform_fuzzer_install "${S}/OWNERS" "${OUT}"/biod_storage_fuzzer --comp "${fuzzer_component_id}"

	platform_fuzzer_install "${S}/OWNERS" "${OUT}"/biod_crypto_validation_value_fuzzer --comp "${fuzzer_component_id}"
}
