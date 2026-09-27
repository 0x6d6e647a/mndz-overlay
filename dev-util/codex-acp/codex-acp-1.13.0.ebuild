# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="ACP adapter for the Codex CLI"
HOMEPAGE="https://github.com/agentclientprotocol/codex-acp"
SRC_URI="
	https://registry.npmjs.org/@agentclientprotocol/codex-acp/-/codex-acp-${PV}.tgz
		-> ${P}.tgz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/codex-acp-${PV}/codex-acp-${PV}-deps.tar.xz
"
S="${WORKDIR}/package"

src_unpack() {
	default_src_unpack
	cd "${T}" || die "Could not cd to temporary directory"
	unpack ${P}-deps.tar.xz
}

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND=">=net-libs/nodejs-22[npm]"
BDEPEND="${RDEPEND}"

# Nested Codex CLI from @openai/codex-linux-x64.
# file: ELF 64-bit LSB pie executable, x86-64, static-pie linked, stripped.
# ldd: statically linked.
# QA_PREBUILT only skips the pre-stripped QA notice. dostrip -x keeps prepstrip off this path.
QA_PREBUILT="usr/lib*/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/bin/codex"

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

	local codex
	for codex in "${ED}"/usr/lib*/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/bin/codex; do
		[[ -f ${codex} ]] || die "prebuilt Codex CLI missing"
		dostrip -x "${codex#"${ED}"}"
	done
}

src_test() {
	# Published npm package omits unit tests (files filter excludes them).
	# Offline CLI smoke using the same deps cache layout as src_install.
	# --help and -v are not smoke commands: any argv other than --version
	# starts an ACP session.
	local prefix="${T}/codex-acp-test-prefix"
	npm \
		--offline \
		--progress false \
		--global \
		--prefix "${prefix}/usr" \
		--cache "${T}/npm-cache" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	local out
	out="$("${prefix}/usr/bin/codex-acp" --version)" || die "codex-acp --version failed"
	[[ "${out}" == "@agentclientprotocol/codex-acp ${PV}" ]] || die "codex-acp --version printed '${out}', expected @agentclientprotocol/codex-acp ${PV}"
}
