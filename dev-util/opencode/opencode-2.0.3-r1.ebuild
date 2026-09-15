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
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bash-completion fish-completion test +webui zsh-completion"
# Bun --compile embeds the app in ELF sections that strip destroys; after
# strip the binary reports host Bun (e.g. 1.4.2) instead of OPENCODE_VERSION.
RESTRICT="strip !test? ( test )"

# ~ allows -rN of this PV (Portage '=' does not match 1.4.2-r1).
BDEPEND="~dev-lang/bun-bin-1.4.2"
RDEPEND="sys-apps/ripgrep"

# InstallTree deps: unpack source + overlay node_modules onto ${S}.
# Avoid default_src_unpack so deps are not also expanded under ${WORKDIR}.
src_unpack() {
	unpack ${P}.tar.gz
	cd "${S}" || die
	unpack ${P}-deps.tar.xz
}

src_compile() {
	export OPENCODE_DISABLE_MODELS_FETCH=1
	export OPENCODE_VERSION="${PV}"
	export OPENCODE_CHANNEL=prod
	export NODE_OPTIONS=--max-old-space-size=4096
	# Deps already installed under ${S} via InstallTree deps tarball.
	cd packages/cli || die
	if use webui; then
		bun-1.4.2 --bun ./script/build.ts --single --skip-install || die
	else
		bun-1.4.2 --bun ./script/build.ts --single --skip-install --skip-web-ui || die
	fi
}

src_install() {
	local bin
	bin="$(find packages/cli/dist/cli-* -type f -path '*/bin/opencode' -executable | head -n1)" || die
	[[ -n ${bin} ]] || die "opencode binary not found under packages/cli/dist/cli-*/bin/opencode"

	exeinto /usr/libexec/opencode
	newexe "${bin}" opencode

	# Installed /usr/bin/opencode is a wrapper. Gentoo updates are emerge,
	# not `opencode upgrade --method curl`. Relative exec so src_install
	# completions via ${ED}/usr/bin/opencode find the image ELF.
	# Do not write ${T}/opencode: the binary mkdir()s that path as TMPDIR.
	cat > "${T}/opencode-wrapper" <<-'EOF' || die
	#!/bin/sh
	export OPENCODE_DISABLE_AUTOUPDATE=1
	exec "$(dirname -- "$0")/../libexec/opencode/opencode" "$@"
	EOF
	newbin "${T}/opencode-wrapper" opencode

	# Running the binary for shell completions can open ftrace's trace_marker
	# (sandbox ACCESS DENIED open_wr without this).
	addwrite /sys/kernel/debug/tracing

	if use bash-completion; then
		"${ED}/usr/bin/opencode" --completions bash > opencode.bash || die
		newbashcomp opencode.bash opencode
	fi
	if use zsh-completion; then
		"${ED}/usr/bin/opencode" --completions zsh > opencode.zsh || die
		newzshcomp opencode.zsh _opencode
	fi
	if use fish-completion; then
		"${ED}/usr/bin/opencode" --completions fish > opencode.fish || die
		newfishcomp opencode.fish opencode.fish
	fi
}

src_test() {
	# Upstream package suite; InstallTree deps already unpacked under ${S}.
	# Known ACP subprocess failures are not skipped.
	export OPENCODE_DISABLE_MODELS_FETCH=1
	cd packages/cli || die
	bun-1.4.2 test --timeout 30000 --only-failures || die
}
