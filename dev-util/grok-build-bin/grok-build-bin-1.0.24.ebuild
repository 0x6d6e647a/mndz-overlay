# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="SpaceXAI coding agent harness and TUI (prebuilt binary)"
HOMEPAGE="https://x.ai/cli https://github.com/xai-org/grok-build"
SRC_URI="
	amd64? ( https://x.ai/cli/grok-${PV}-linux-x86_64 -> grok-${PV}-linux-amd64 )
	arm64? ( https://x.ai/cli/grok-${PV}-linux-aarch64 -> grok-${PV}-linux-arm64 )
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="bash-completion fish-completion zsh-completion"
RESTRICT="mirror strip bindist"

QA_PREBUILT="usr/bin/grok"

S="${WORKDIR}"

src_compile() {
	local distfile
	case ${ARCH} in
		amd64) distfile="${DISTDIR}/grok-${PV}-linux-amd64" ;;
		arm64) distfile="${DISTDIR}/grok-${PV}-linux-arm64" ;;
		*) die "Unsupported ARCH: ${ARCH}" ;;
	esac

	# Upstream CLI name is "grok" (install.sh links grok + agent to the same binary).
	cp "${distfile}" grok || die
	chmod +x grok || die

	if use bash-completion; then
		./grok completions bash > grok.bash ||
			die 'Unable to generate bash completions'
	fi
	if use fish-completion; then
		./grok completions fish > grok.fish ||
			die 'Unable to generate fish completions'
	fi
	if use zsh-completion; then
		./grok completions zsh > _grok ||
			die 'Unable to generate zsh completions'
	fi
}

src_install() {
	exeinto /usr/bin
	doexe grok
	# Match official installer: agent is an alias for the same binary.
	dosym grok /usr/bin/agent

	use bash-completion &&
		newbashcomp grok.bash grok
	use fish-completion &&
		newfishcomp grok.fish grok.fish
	use zsh-completion &&
		newzshcomp _grok _grok
}
