# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Node.js native addon build tool"
HOMEPAGE="https://github.com/nodejs/node-gyp"
SRC_URI="
	https://registry.npmjs.org/node-gyp/-/node-gyp-${PV}.tgz
		-> ${P}.tgz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/node-gyp-${PV}/node-gyp-${PV}-deps.tar.xz
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

RDEPEND="
	>=net-libs/nodejs-22.22.2[npm]
	dev-lang/python
"
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

	local gyp_js
	gyp_js="$(find "${ED}/usr" -type f -path '*/node_modules/node-gyp/bin/node-gyp.js' -print -quit)" || die
	[[ -n ${gyp_js} ]] || die "node-gyp.js not found after npm install"
	local gyp_rel="${gyp_js#"${ED}"}"

	rm -f "${ED}/usr/bin/node-gyp" "${ED}/usr/sbin/node-gyp" || die
	cat > "${T}/node-gyp" <<-EOF || die
	#!/bin/sh
	[ -n "\${npm_config_nodedir}" ] || export npm_config_nodedir=/usr
	[ -n "\${npm_config_python}" ] || export npm_config_python=/usr/bin/python3
	[ -n "\${PYTHON}" ] || export PYTHON=/usr/bin/python3
	exec node ${gyp_rel} "\$@"
	EOF
	newbin "${T}/node-gyp" node-gyp
}

src_test() {
	local prefix="${T}/node-gyp-test-prefix"
	npm \
		--offline \
		--progress false \
		--global \
		--prefix "${prefix}/usr" \
		--cache "${T}/npm-cache" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	"${prefix}/usr/bin/node-gyp" --version || die "node-gyp --version failed"
}
