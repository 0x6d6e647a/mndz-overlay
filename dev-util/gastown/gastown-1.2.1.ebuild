# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

BDEPEND=">=dev-lang/go-1.25.8:="

DESCRIPTION="Gas Town – workspace manager for multi-agent coding"
HOMEPAGE="https://github.com/gastownhall/gastown"
SRC_URI="https://github.com/gastownhall/gastown/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/gastown-${PV}/gastown-${PV}-vendor.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~mips ~ppc64 ~riscv ~s390 ~x64-macos ~x64-solaris ~x86"
IUSE="bash-completion fish-completion +tmux test zsh-completion"
RESTRICT="!test? ( test )"

# gastown-beads-window: min=0.57.0 max=none
RDEPEND="
	~dev-util/beads-1.0.4
	>=dev-db/dolt-2.0.7
	dev-vcs/git
	tmux? ( app-misc/tmux )
"

src_compile() {
	export CGO_ENABLED=0
	ego build \
		-ldflags "-s -w -X github.com/steveyegge/gastown/internal/cmd.Version=${PV} -X github.com/steveyegge/gastown/internal/cmd.BuiltProperly=1" \
		-v -x -work -o "${T}/gt" ./cmd/gt
}

src_install() {
	einstalldocs
	dobin "${T}/gt"

	# completion is exempt from the beads/town checks and needs no workspace.
	if use bash-completion; then
		"${T}/gt" completion bash > gt.bash || die "failed to generate bash completion"
		newbashcomp gt.bash gt
	fi
	if use fish-completion; then
		"${T}/gt" completion fish > gt.fish || die "failed to generate fish completion"
		newfishcomp gt.fish gt.fish
	fi
	if use zsh-completion; then
		"${T}/gt" completion zsh > gt.zsh || die "failed to generate zsh completion"
		newzshcomp gt.zsh _gt
	fi
}

src_test() {
	ego test -short ./...
}
