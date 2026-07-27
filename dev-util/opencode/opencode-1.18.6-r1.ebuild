# Copyright 2021-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="The open source coding agent"
HOMEPAGE="https://opencode.ai"
SRC_URI="
	https://github.com/anomalyco/opencode/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/opencode-${PV}/opencode-${PV}-deps.tar.xz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/opencode-${PV}/opencode-${PV}-models.json
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bash-completion test +webui zsh-completion"
# Bun --compile embeds the app in ELF sections that strip destroys; after
# strip the binary reports host Bun (e.g. 1.3.14) instead of OPENCODE_VERSION.
RESTRICT="strip !test? ( test )"

BDEPEND=">=dev-lang/bun-bin-1.3.14"
RDEPEND="sys-apps/ripgrep"

# InstallTree deps: unpack source + overlay node_modules onto ${S}.
# Models JSON stays in DISTDIR (MODELS_DEV_API_JSON); do not unpack it.
# Avoid default_src_unpack so deps are not also expanded under ${WORKDIR}.
src_unpack() {
	unpack ${P}.tar.gz
	cd "${S}" || die
	unpack ${P}-deps.tar.xz
}

src_compile() {
	export MODELS_DEV_API_JSON="${DISTDIR}/${PN}-${PV}-models.json"
	export OPENCODE_DISABLE_MODELS_FETCH=1
	export OPENCODE_VERSION="${PV}"
	export OPENCODE_CHANNEL=stable
	# Deps already installed under ${S} via InstallTree deps tarball.
	cd packages/opencode || die
	if use webui; then
		bun --bun ./script/build.ts --single --skip-install || die
	else
		bun --bun ./script/build.ts --single --skip-install --skip-embed-web-ui || die
	fi
}

src_install() {
	local bin
	bin="$(find packages/opencode/dist -type f -name opencode -executable | head -n1)" || die
	[[ -n ${bin} ]] || die "opencode binary not found under packages/opencode/dist"
	dobin "${bin}"

	# Running the binary for shell completions can open ftrace's trace_marker
	# (sandbox ACCESS DENIED open_wr without this).
	addwrite /sys/kernel/debug/tracing

	if use bash-completion; then
		SHELL=/bin/bash "${ED}/usr/bin/opencode" completion > opencode.bash || die
		newbashcomp opencode.bash opencode
	fi
	if use zsh-completion; then
		SHELL=/bin/zsh "${ED}/usr/bin/opencode" completion > opencode.zsh || die
		newzshcomp opencode.zsh _opencode
	fi
}

src_test() {
	# Upstream package suite; InstallTree deps already unpacked under ${S}.
	cd packages/opencode || die
	bun test --timeout 30000 --only-failures || die
}
