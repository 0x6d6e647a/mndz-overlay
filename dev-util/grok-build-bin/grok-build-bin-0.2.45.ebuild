# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

GROK_PN="${PN//-bin/}"

DESCRIPTION="xAI Grok command line interface (prebuilt binary)"
HOMEPAGE="https://x.ai/cli"
SRC_URI="
	amd64? ( https://x.ai/cli/grok-${PV}-linux-x86_64 -> grok-${PV}-linux-amd64 )
	arm64? ( https://x.ai/cli/grok-${PV}-linux-aarch64 -> grok-${PV}-linux-arm64 )
"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="bash-completion fish-completion zsh-completion"
RESTRICT="mirror strip bindist"

S="${WORKDIR}"

src_compile() {
	local distfile
	case ${ARCH} in
		amd64) distfile="${DISTDIR}/grok-${PV}-linux-amd64" ;;
		arm64) distfile="${DISTDIR}/grok-${PV}-linux-arm64" ;;
		*) die "Unsupported ARCH: ${ARCH}" ;;
	esac

	cp "${distfile}" "${GROK_PN}" || die
	chmod +x "${GROK_PN}" || die

	if use bash-completion; then
		./"${GROK_PN}" completions bash > grok.bash ||
			die 'Unable to generate bash completions'
	fi
	if use fish-completion; then
		./"${GROK_PN}" completions fish > grok.fish ||
			die 'Unable to generate fish completions'
	fi
	if use zsh-completion; then
		./"${GROK_PN}" completions zsh > _grok ||
			die 'Unable to generate zsh completions'
	fi
}

src_install() {
	exeinto /usr/bin
	doexe "${GROK_PN}"
	dosym "${GROK_PN}" /usr/bin/agent

	use bash-completion &&
		newbashcomp grok.bash "${GROK_PN}"
	use fish-completion &&
		newfishcomp grok.fish grok.fish
	use zsh-completion &&
		newzshcomp _grok "_${GROK_PN}"
}
