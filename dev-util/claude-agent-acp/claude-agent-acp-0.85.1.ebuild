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
IUSE="bundled-claude test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=net-libs/nodejs-22[npm]
	!bundled-claude? ( dev-util/claude-code )
"
BDEPEND="${RDEPEND}"

# Nested glibc x86-64 Claude CLI from the optional SDK package.
# QA_PREBUILT only skips the pre-stripped QA notice. dostrip -x is what
# stops prepstrip from removing .symtab.
# The pattern stays set when bundled-claude is off; an absent match is not a QA failure.
QA_PREBUILT="usr/lib*/node_modules/@agentclientprotocol/claude-agent-acp/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude"

src_install() {
	local npm_args=(
		--offline
		--verbose
		--progress false
		--foreground-scripts
		--global
		--prefix "${ED}/usr"
		--cache "${T}/npm-cache"
	)
	if ! use bundled-claude; then
		npm_args+=( --omit=optional )
	fi
	npm "${npm_args[@]}" \
		install "${DISTDIR}/${P}.tgz" || die "npm install failed"

	if use bundled-claude; then
		local claude
		for claude in "${ED}"/usr/lib*/node_modules/@agentclientprotocol/claude-agent-acp/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude; do
			[[ -f ${claude} ]] || die "prebuilt Claude CLI missing"
			dostrip -x "${claude#"${ED}"}"
		done
	else
		# npm --global still extracts this transitive optional platform package.
		local bundled
		for bundled in "${ED}"/usr/lib*/node_modules/@agentclientprotocol/claude-agent-acp/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64; do
			[[ -e ${bundled} ]] || continue
			rm -rf "${bundled}" || die "could not remove bundled Claude CLI"
		done
		# Point the adapter at gentoo Claude Code unless the operator already set CLAUDE_CODE_EXECUTABLE.
		rm -f "${ED}/usr/bin/claude-agent-acp" || die "could not remove npm bin"
		local entries=( "${ED}"/usr/lib*/node_modules/@agentclientprotocol/claude-agent-acp/dist/index.js )
		[[ ${#entries[@]} -eq 1 && -f ${entries[0]} ]] || die "adapter entrypoint missing"
		local entry="${entries[0]#"${ED}"}"
		cat > "${T}/claude-agent-acp" <<EOF || die "could not write claude-agent-acp wrapper"
#!/bin/sh
if [ -z "\${CLAUDE_CODE_EXECUTABLE+x}" ]; then
	export CLAUDE_CODE_EXECUTABLE=/opt/bin/claude
fi
exec node "${entry}" "\$@"
EOF
		dobin "${T}/claude-agent-acp"
	fi
}

src_test() {
	# Published npm package omits unit tests (files filter excludes them).
	# Offline CLI smoke using the same deps cache layout as src_install.
	# --help is not a smoke command: with stdin closed it opens an ACP session.
	local prefix="${T}/claude-agent-acp-test-prefix"
	local npm_args=(
		--offline
		--progress false
		--global
		--prefix "${prefix}/usr"
		--cache "${T}/npm-cache"
	)
	if ! use bundled-claude; then
		npm_args+=( --omit=optional )
	fi
	npm "${npm_args[@]}" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	local out
	out="$("${prefix}/usr/bin/claude-agent-acp" --version)" || die "claude-agent-acp --version failed"
	[[ "${out}" == "${PV}" ]] || die "claude-agent-acp --version printed '${out}', expected ${PV}"
}
