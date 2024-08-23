cros_pre_src_prepare_fingerprint_patch() {
  if [ ${PV} == '9999' ]; then
    return
  fi
  eapply ${FINGERPRINT_BASHRC_FILESDIR}/001-add-libfprint.patch
  eapply ${FINGERPRINT_BASHRC_FILESDIR}/002-update-biod-conf.patch
  eapply ${FINGERPRINT_BASHRC_FILESDIR}/003-add-mafp.patch
}
