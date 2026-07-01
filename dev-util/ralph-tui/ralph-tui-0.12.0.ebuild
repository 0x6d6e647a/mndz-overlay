# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="AI Agent Loop Orchestrator TUI"
HOMEPAGE="https://github.com/subsy/ralph-tui"
SRC_URI="
	https://github.com/subsy/ralph-tui/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/ralph-tui-${PV}/ralph-tui-${PV}-deps.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

IUSE="test"

BDEPEND=">=dev-lang/bun-bin-1.3.6"
RDEPEND="${BDEPEND}"

src_unpack() {
	default_src_unpack
	cd "${T}" || die
	unpack ${P}-deps.tar.xz
}

src_compile() {
	bun install --frozen-lockfile --cache-dir "${T}/bun-cache" || die
	bun run build || die
}

src_install() {
	exeinto /usr/bin
	doexe dist/cli.js
	dosym /usr/bin/cli.js /usr/bin/ralph-tui

	einstalldocs
}

src_test() {
	if use test; then
		bun test || die
	fi
}
