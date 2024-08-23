fingerprint_stack_bashrc() {
  local cfg cfgd
  cfgd="/mnt/host/source/src/overlays/project-openfyde-fingerprint/${CATEGORY}/${PN}"
  for cfg in ${PN} ${P} ${PF} ; do
    cfg="${cfgd}/${cfg}.bashrc"
    [[ -f ${cfg} ]] && . "${cfg}"
  done

  export FINGERPRINT_BASHRC_FILESDIR="${cfgd}/files"
}

fingerprint_stack_bashrc
