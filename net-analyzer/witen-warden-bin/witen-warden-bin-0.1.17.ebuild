# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker systemd

DESCRIPTION="Witen Warden log-tailing jailer (prebuilt binary)"
HOMEPAGE="https://www.witenlabs.com"
SRC_URI="
	https://www.witenlabs.com/api/releases/warden/artifacts/witen-warden-${PV}-linux-amd64-glibc.tar.gz
	https://www.witenlabs.com/api/releases/warden/artifacts/witen-warden_${PV}-1_amd64.deb
"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="iptables"
RESTRICT="bindist mirror strip"

QA_PREBUILT="usr/bin/warden"

RDEPEND="
	app-misc/ca-certificates
	net-firewall/nftables
	sys-apps/acl
	virtual/logger
	iptables? ( net-firewall/iptables )
"

pkg_setup() {
	if ! getent group witen-warden >/dev/null; then
		groupadd --system witen-warden || die "failed to create group witen-warden"
	fi
	if ! getent passwd witen-warden >/dev/null; then
		useradd \
			--system \
			--gid witen-warden \
			--home-dir /var/lib/witen \
			--create-home \
			--shell /sbin/nologin \
			witen-warden \
			|| die "failed to create user witen-warden"
	fi
}

src_install() {
	# unpacker extracts the deb and does not run its maintainer scripts.
	# The portable install.sh is not executed.

	exeinto /usr/bin
	doexe usr/bin/warden

	exeinto /usr/libexec/witen-warden
	doexe \
		usr/libexec/witen-warden/prepare-state \
		usr/libexec/witen-warden/prepare-log-access \
		usr/libexec/witen-warden/smoke-journal

	systemd_dounit usr/lib/systemd/system/witen-warden.service
	grep -q 'ExecStart=/usr/bin/warden' \
		usr/lib/systemd/system/witen-warden.service \
		|| die "systemd unit does not start /usr/bin/warden"

	local portable="${WORKDIR}/witen-warden-${PV}-linux-amd64-glibc"
	sed -e 's|/usr/local/bin/warden|/usr/bin/warden|g' \
		"${portable}/witen-warden.openrc" > "${T}/witen-warden.openrc" || die
	sed -e 's|/usr/local/bin/warden|/usr/bin/warden|g' \
		"${portable}/witen-warden.confd" > "${T}/witen-warden.confd" || die
	grep -q '/usr/bin/warden' "${T}/witen-warden.openrc" \
		|| die "OpenRC command path was not rewritten"
	grep -q '/usr/bin/warden' "${T}/witen-warden.confd" \
		|| die "conf.d command path was not rewritten"
	if grep -q '/usr/local/bin/warden' "${T}/witen-warden.openrc" \
		"${T}/witen-warden.confd"; then
		die "OpenRC files still name /usr/local/bin/warden"
	fi
	newinitd "${T}/witen-warden.openrc" witen-warden
	newconfd "${T}/witen-warden.confd" witen-warden

	insinto /etc/logrotate.d
	newins "${portable}/witen-warden.logrotate" witen-warden

	# Mode 0640, group witen-warden. pkg_postinst repeats that when this
	# merge created the file; config-protect leaves an operator copy alone.
	insinto /etc/witen
	insopts -m0640
	doins etc/witen/warden.toml
	fowners root:witen-warden /etc/witen/warden.toml
	insopts -m0644

	insinto /usr/share/bash-completion/completions
	doins usr/share/bash-completion/completions/warden

	doman \
		usr/share/man/man8/warden.8 \
		usr/share/man/man5/warden.toml.5

	local callers
	for callers in \
		"${portable}/local-callers.md" \
		"${WORKDIR}/usr/share/doc/witen-warden/local-callers.md"
	do
		if [[ -f ${callers} ]]; then
			dodoc "${callers}"
			break
		fi
	done
}

pkg_postinst() {
	local cfg="${EROOT}/etc/witen/warden.toml"
	local pending=( "${EROOT}"/etc/witen/._cfg????_warden.toml )
	if [[ -f ${cfg} && ! -e ${pending[0]} && -z ${REPLACING_VERSIONS} ]]; then
		chmod 0640 "${cfg}" || die "chmod ${cfg}"
		chgrp witen-warden "${cfg}" || die "chgrp ${cfg}"
	fi
}
