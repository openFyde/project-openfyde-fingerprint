# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_USE_VCSID="1"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk biod chromeos-config libec metrics .gn"

PLATFORM_SUBDIR="biod"

inherit cros-fuzzer cros-sanitizers cros-workon cros-unibuild platform udev user

DESCRIPTION="Biometrics Daemon for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/biod/README.md"

LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE="
	fp_on_power_button
	fpmcu_firmware_bloonchipper
	fpmcu_firmware_dartmonkey
	fpmcu_firmware_nami
	fpmcu_firmware_nocturne
	fuzzer
  libfprint
"

COMMON_DEPEND="
	chromeos-base/chromeos-config-tools:=
	chromeos-base/libec:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	sys-apps/flashmap:=
"

# For biod_client_tool. The biod_proxy library will be built on all boards but
# biod_client_tool will be built only on boards with biod.
COMMON_DEPEND+="
	chromeos-base/biod_proxy:=
"

RDEPEND="
	${COMMON_DEPEND}
	sys-apps/flashrom
	virtual/chromeos-firmware-fpmcu
	"

# Release branch firmware.
# The USE flags below come from USE_EXPAND variables.
# See third_party/chromiumos-overlay/profiles/base/make.defaults.
RDEPEND+="
	fpmcu_firmware_bloonchipper? ( sys-firmware/chromeos-fpmcu-release-bloonchipper )
	fpmcu_firmware_dartmonkey? ( sys-firmware/chromeos-fpmcu-release-dartmonkey )
	fpmcu_firmware_nami? ( sys-firmware/chromeos-fpmcu-release-nami )
	fpmcu_firmware_nocturne? ( sys-firmware/chromeos-fpmcu-release-nocturne )
  libfprint? ( sys-auth/libfprint )
"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/chromeos-ec-headers:=
	chromeos-base/power_manager-client:=
	chromeos-base/system_api:=[fuzzer?]
	dev-libs/openssl:=
"

pkg_setup() {
	enewuser biod
	enewgroup biod
}

src_install() {
	dobin "${OUT}"/biod

	dobin "${OUT}"/bio_crypto_init
	dobin "${OUT}"/bio_wash

	dosbin "${OUT}"/bio_fw_updater

	into /usr/local
	dobin "${OUT}"/biod_client_tool

	insinto /usr/share/policy
	local seccomp_src_dir="init/seccomp"

	newins "${seccomp_src_dir}/biod-seccomp-${ARCH}.policy" \
		biod-seccomp.policy

	newins "${seccomp_src_dir}/bio-crypto-init-seccomp-${ARCH}.policy" \
		bio-crypto-init-seccomp.policy
	insinto /etc/init
  if use libfprint; then
    doins ${FILESDIR}/init/*.conf
  else
	  doins init/*.conf
  fi
	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.BiometricsDaemon.conf

	udev_dorules udev/99-biod.rules

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

platform_pkg_test() {
	platform_test "run" "${OUT}/biod_test_runner"
}
