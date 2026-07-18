# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

BDEPEND=">=dev-lang/go-1.26.2:="

DESCRIPTION="bd – Beads: Distributed graph issue tracker for AI agents"
HOMEPAGE="https://github.com/gastownhall/beads"
SRC_URI="https://github.com/gastownhall/beads/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/beads-${PV}/beads-${PV}-vendor.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

src_compile() {
	export CGO_ENABLED=1
	ego build -tags gms_pure_go -ldflags "-s -w -X main.Version=${PV}" -v -x -work -o bd ./cmd/bd
}

src_install() {
	einstalldocs
	dobin bd
}

src_test() {
	ego test ./...
}
