# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

BDEPEND=">=dev-lang/go-1.26.4:="

DESCRIPTION="Crush – Terminal-based AI coding assistant"
HOMEPAGE="https://github.com/charmbracelet/crush"
SRC_URI="https://github.com/charmbracelet/crush/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/crush-${PV}/crush-${PV}-vendor.tar.xz"

LICENSE="FSL-1.1-MIT"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ~mips ppc64 ~riscv ~s390 ~x64-macos ~x64-solaris x86"

src_compile() {
	export CGO_ENABLED=0
	export GOEXPERIMENT=greenteagc
	ego build -ldflags "-s -w -X github.com/charmbracelet/crush/internal/version.Version=${PV}" -v -x -work -o crush .
}

src_install() {
	einstalldocs
	dobin crush
}

src_test() {
	ego test ./...
}
