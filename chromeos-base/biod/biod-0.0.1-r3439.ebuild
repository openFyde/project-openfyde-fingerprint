# Copyright 2016 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="aace9a0b19e922f7c57f6e061bbcb8bbad1233e0"
CROS_WORKON_TREE=("80d4baed48e7c7c409c7ef85445449ee538906d7" "9c4d2984ccb8a2513e19ced8240170cafe37fd78" "95f897e6a02bd1183f425972401eed585c0c8c32" "bcafb6930f45c98b5ec0a5e37124f614f3b6483f" "0a6005e662dd5d3c712d1cb1c78f713e1744c535" "a10269602c120683d70021b605b4e705db7bddf2" "544e5cda3225c9cd373e1431dcb270e85d82bda5" "b1a2e02e884ce6ecf10f2382a4f4775ff4b3d226" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
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
			sys-firmware/chromeos-zephyr-fpmcu-release-bloonchipper
		)
		fpmcu_firmware_buccaneer? ( sys-firmware/chromeos-fpmcu-release-buccaneer )
		fpmcu_firmware_dartmonkey? ( sys-firmware/chromeos-fpmcu-release-dartmonkey )
		fpmcu_firmware_gwendolin? ( sys-firmware/chromeos-fpmcu-release-gwendolin )
		fpmcu_firmware_helipilot? ( sys-firmware/chromeos-fpmcu-release-helipilot )
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
