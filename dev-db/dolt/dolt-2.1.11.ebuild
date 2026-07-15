# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Dolt – Git for Data"
HOMEPAGE="https://github.com/dolthub/dolt"
SRC_URI="https://github.com/dolthub/dolt/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/dolt-${PV}/dolt-${PV}-vendor.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

S="${WORKDIR}/${P}/go"

src_compile() {
	ego build -ldflags "-s -w -X 'github.com/dolthub/dolt/go/cmd/dolt/doltversion.Version=${PV}'" -v -x -work -o "${PN}" "./cmd/${PN}"
}

src_install() {
	einstalldocs
	dobin dolt
}

src_test() {
	ego test ./...
}
