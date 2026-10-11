# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Unified AI-agent configuration generator CLI"
HOMEPAGE="https://github.com/dyoshikawa/rulesync"
SRC_URI="
	https://registry.npmjs.org/rulesync/-/rulesync-${PV}.tgz
		-> ${P}.tgz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/rulesync-${PV}/rulesync-${PV}-deps.tar.xz
"
S="${WORKDIR}/package"

src_unpack() {
	default_src_unpack
	cd "${T}" || die "Could not cd to temporary directory"
	unpack ${P}-deps.tar.xz
}

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~x64-macos ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND=">=net-libs/nodejs-22.0.0[npm]"
BDEPEND="${RDEPEND}"

src_install() {
	npm \
		--offline \
		--verbose \
		--progress false \
		--foreground-scripts \
		--global \
		--prefix "${ED}/usr" \
		--cache "${T}/npm-cache" \
		install "${DISTDIR}/${P}.tgz" || die "npm install failed"
}

src_test() {
	# Published npm package omits unit tests (files filter excludes them).
	# Offline CLI smoke using the same deps cache layout as src_install.
	local prefix="${T}/rulesync-test-prefix"
	npm \
		--offline \
		--progress false \
		--global \
		--prefix "${prefix}/usr" \
		--cache "${T}/npm-cache" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	"${prefix}/usr/bin/rulesync" --help >/dev/null || die "rulesync --help failed"
}
