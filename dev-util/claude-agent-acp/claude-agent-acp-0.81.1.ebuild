# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="ACP adapter for the Claude Agent SDK"
HOMEPAGE="https://github.com/agentclientprotocol/claude-agent-acp"
SRC_URI="
	https://registry.npmjs.org/@agentclientprotocol/claude-agent-acp/-/claude-agent-acp-${PV}.tgz
		-> ${P}.tgz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/claude-agent-acp-${PV}/claude-agent-acp-${PV}-deps.tar.xz
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

# Nested glibc x86-64 Claude CLI from the optional SDK package. Do not strip it.
QA_PREBUILT="usr/lib*/node_modules/@agentclientprotocol/claude-agent-acp/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude"

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
	# --help is not a smoke command: with stdin closed it opens an ACP session.
	local prefix="${T}/claude-agent-acp-test-prefix"
	npm \
		--offline \
		--progress false \
		--global \
		--prefix "${prefix}/usr" \
		--cache "${T}/npm-cache" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	local out
	out="$("${prefix}/usr/bin/claude-agent-acp" --version)" || die "claude-agent-acp --version failed"
	[[ "${out}" == "${PV}" ]] || die "claude-agent-acp --version printed '${out}', expected ${PV}"
}
