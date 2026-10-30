# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Shared OFL fonts for Storytold craft apps"
HOMEPAGE="https://github.com/storytold/craft-fonts"
SRC_URI="https://github.com/storytold/craft-fonts/archive/aced4137c022f1f587624d48e81ec77e1914a9cc.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/craft-fonts-aced4137c022f1f587624d48e81ec77e1914a9cc"

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
