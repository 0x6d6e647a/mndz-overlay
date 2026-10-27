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
IUSE="bundled-codex external-codex test"
REQUIRED_USE="?? ( bundled-codex external-codex )"
RESTRICT="!test? ( test )"

RDEPEND="
	>=net-libs/nodejs-22[npm]
	!bundled-codex? ( !external-codex? ( dev-util/codex ) )
"
BDEPEND="${RDEPEND}"

# Nested Codex CLI from @openai/codex-linux-x64.
# file: ELF 64-bit LSB pie executable, x86-64, static-pie linked, stripped.
# ldd: statically linked.
# QA_PREBUILT only skips the pre-stripped QA notice. dostrip -x keeps prepstrip off this path.
# The pattern stays set when bundled-codex is off; an absent match is not a QA failure.
QA_PREBUILT="usr/lib*/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/bin/codex"

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
	if ! use bundled-codex; then
		npm_args+=( --omit=optional )
	fi
	npm "${npm_args[@]}" \
		install "${DISTDIR}/${P}.tgz" || die "npm install failed"

	if use bundled-codex; then
		local codex
		for codex in "${ED}"/usr/lib*/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/bin/codex; do
			[[ -f ${codex} ]] || die "prebuilt Codex CLI missing"
			dostrip -x "${codex#"${ED}"}"
		done
	else
		# npm --global still extracts this transitive optional platform package.
		local bundled
		for bundled in "${ED}"/usr/lib*/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex-linux-x64; do
			[[ -e ${bundled} ]] || continue
			rm -rf "${bundled}" || die "could not remove bundled Codex CLI"
		done
		# external-codex leaves the npm bin. The operator sets CODEX_PATH.
		if ! use external-codex; then
			# Point the adapter at the system Codex unless the operator already set CODEX_PATH.
			rm -f "${ED}/usr/bin/codex-acp" || die "could not remove npm bin"
			local entries=( "${ED}"/usr/lib*/node_modules/@agentclientprotocol/codex-acp/dist/index.js )
			[[ ${#entries[@]} -eq 1 && -f ${entries[0]} ]] || die "adapter entrypoint missing"
			local entry="${entries[0]#"${ED}"}"
			cat > "${T}/codex-acp" <<EOF || die "could not write codex-acp wrapper"
#!/bin/sh
if [ -z "\${CODEX_PATH+x}" ]; then
	export CODEX_PATH=/usr/bin/codex
fi
exec node "${entry}" "\$@"
EOF
			dobin "${T}/codex-acp"
		fi
	fi
}

src_test() {
	# Published npm package omits unit tests (files filter excludes them).
	# Offline CLI smoke using the same deps cache layout as src_install.
	# --help and -v are not smoke commands: any argv other than --version
	# starts an ACP session.
	local prefix="${T}/codex-acp-test-prefix"
	local npm_args=(
		--offline
		--progress false
		--global
		--prefix "${prefix}/usr"
		--cache "${T}/npm-cache"
	)
	if ! use bundled-codex; then
		npm_args+=( --omit=optional )
	fi
	npm "${npm_args[@]}" \
		install "${DISTDIR}/${P}.tgz" || die "npm install for tests failed"
	local out
	out="$("${prefix}/usr/bin/codex-acp" --version)" || die "codex-acp --version failed"
	[[ "${out}" == "@agentclientprotocol/codex-acp ${PV}" ]] || die "codex-acp --version printed '${out}', expected @agentclientprotocol/codex-acp ${PV}"
}
