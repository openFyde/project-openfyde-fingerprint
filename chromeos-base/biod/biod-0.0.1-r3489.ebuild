# Copyright 2016 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="86656621c0ed9f92196ab93e176df6ee5c51c56f"
CROS_WORKON_TREE=("80d4baed48e7c7c409c7ef85445449ee538906d7" "585ba4d7a418f3b666b104b27d683bbb6ba90d7e" "a2a00d640fbf4809c60065d23f775043ca22bc1e" "8a88fc27ad7194576005a9c85f3629996e4a15ad" "369a70bf72ea92298a6e2e8b7a500453e503a12f" "80939ad83b8001fb19198ab7e719925c124a4f6a" "fd1ab55bfbe3f597d446ba2bce050e54013f473a" "d308409644dd989573e0b6d181527438c5c76847" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_WORKON_USE_VCSID="1"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk biod chromeos-config featured libec libhwsec libhwsec-foundation metrics .gn"

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
	fpmcu_firmware_gwendolin
	fpmcu_firmware_helipilot
	fpmcu_firmware_nami
	fpmcu_firmware_nocturne
	fpmcu_firmware_rosalia
	fuzzer
	test
	libfprint
	mafp
"
# We must depend on libusb because libec headers make use of libusb.
COMMON_DEPEND="
	chromeos-base/chromeos-config-tools:=
	chromeos-base/featured:=
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
		)
		fpmcu_firmware_buccaneer? (
			sys-firmware/chromeos-fpmcu-release-buccaneer
			sys-firmware/chromeos-zephyr-fpmcu-release-buccaneer
		)
		fpmcu_firmware_dartmonkey? ( sys-firmware/chromeos-fpmcu-release-dartmonkey )
		fpmcu_firmware_gwendolin? ( sys-firmware/chromeos-fpmcu-release-gwendolin )
		fpmcu_firmware_helipilot? (
			sys-firmware/chromeos-fpmcu-release-helipilot
			sys-firmware/chromeos-zephyr-fpmcu-release-helipilot
		)
		fpmcu_firmware_nami? ( sys-firmware/chromeos-fpmcu-release-nami )
		fpmcu_firmware_nocturne? ( sys-firmware/chromeos-fpmcu-release-nocturne )
		fpmcu_firmware_rosalia? ( sys-firmware/chromeos-fpmcu-release-rosalia )
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
