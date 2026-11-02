# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Kiro CLI coding agent (prebuilt binaries)"
HOMEPAGE="https://kiro.dev/cli"
# Upstream basenames omit the version. GitMv keeps the previous ebuild, so the
# distfile name has to carry ${PV} or one Manifest cannot hash both archives.
SRC_URI="
	amd64? (
		elibc_glibc? (
			https://desktop-release.q.us-east-1.amazonaws.com/${PV}/kirocli-x86_64-linux.tar.xz
				-> kirocli-${PV}-x86_64-linux.tar.xz
		)
		elibc_musl? (
			https://desktop-release.q.us-east-1.amazonaws.com/${PV}/kirocli-x86_64-linux-musl.tar.xz
				-> kirocli-${PV}-x86_64-linux-musl.tar.xz
		)
	)
	arm64? (
		elibc_glibc? (
			https://desktop-release.q.us-east-1.amazonaws.com/${PV}/kirocli-aarch64-linux.tar.xz
				-> kirocli-${PV}-aarch64-linux.tar.xz
		)
		elibc_musl? (
			https://desktop-release.q.us-east-1.amazonaws.com/${PV}/kirocli-aarch64-linux-musl.tar.xz
				-> kirocli-${PV}-aarch64-linux-musl.tar.xz
		)
	)
"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip"

QA_PREBUILT="usr/bin/kiro-cli usr/bin/kiro-cli-chat usr/bin/kiro-cli-term"

RDEPEND="elibc_glibc? ( >=sys-libs/glibc-2.34 )"

S="${WORKDIR}/kirocli"

src_install() {
	exeinto /usr/bin
	doexe bin/kiro-cli bin/kiro-cli-chat bin/kiro-cli-term
}

pkg_postinst() {
	elog "kiro-cli settings app.disableAutoupdates true"
}
