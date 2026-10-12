# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Shared OFL fonts for Storytold craft apps"
HOMEPAGE="https://github.com/storytold/craft-fonts"
SRC_URI="https://github.com/storytold/craft-fonts/archive/3d9ab3a132ed0eff457e424226a435a901da30d3.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/craft-fonts-3d9ab3a132ed0eff457e424226a435a901da30d3"

LICENSE="OFL-1.1"
SLOT="0/${PV}"
KEYWORDS="-* ~amd64 ~x86 ~arm ~arm64 ~ppc64 ~loong ~riscv ~sparc ~s390"

# The snapshot is font data. Do not build the repository's Rust crate.
src_compile() {
	:
}

src_install() {
	insinto /usr/share/craft-fonts
	doins -r fonts
}
