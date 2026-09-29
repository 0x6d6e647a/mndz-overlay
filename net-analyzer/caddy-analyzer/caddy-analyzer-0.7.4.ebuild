# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module optfeature shell-completion

DESCRIPTION="Caddy access log analyzer, security inspector, and TUI dashboard"
HOMEPAGE="https://github.com/lenny-ts/caddy-analyzer"
SRC_URI="
	https://github.com/lenny-ts/caddy-analyzer/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/airencracken/mndz-overlay-assets/releases/download/caddy-analyzer-${PV}/caddy-analyzer-${PV}-vendor.tar.xz
"

LICENSE="Apache-2.0 BSD ISC MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64"
IUSE="bash-completion fish-completion test zsh-completion"
RESTRICT="!test? ( test )"

BDEPEND=">=dev-lang/go-1.25.13:="

PATCHES=( "${FILESDIR}/caddy-analyzer-0.7.4-offline-geoip.patch" )

src_compile() {
	export CGO_ENABLED=0
	ego build -buildvcs=false \
		-ldflags "-X github.com/lenny-ts/caddy-analyzer/cmd.Version=${PV}" \
		-o "${T}/caddy-analyze" ./cmd/caddy-analyze
}

src_test() {
	export XDG_CONFIG_HOME="${T}/config"
	ego test ./...
}

src_install() {
	einstalldocs
	dobin "${T}/caddy-analyze"

	if use bash-completion; then
		"${T}/caddy-analyze" completion bash > "${T}/caddy-analyze.bash" \
			|| die "failed to generate bash completion"
		newbashcomp "${T}/caddy-analyze.bash" caddy-analyze
	fi
	if use fish-completion; then
		"${T}/caddy-analyze" completion fish > "${T}/caddy-analyze.fish" \
			|| die "failed to generate fish completion"
		newfishcomp "${T}/caddy-analyze.fish" caddy-analyze.fish
	fi
	if use zsh-completion; then
		"${T}/caddy-analyze" completion zsh > "${T}/_caddy-analyze" \
			|| die "failed to generate zsh completion"
		newzshcomp "${T}/_caddy-analyze" _caddy-analyze
	fi
}

pkg_postinst() {
	optfeature "iptables firewall backend for guard, block, and unban" net-firewall/iptables
	optfeature "nftables firewall backend for guard" net-firewall/nftables
}
