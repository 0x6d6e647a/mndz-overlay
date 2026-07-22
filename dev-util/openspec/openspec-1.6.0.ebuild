# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="AI-native system for spec-driven development"
HOMEPAGE="https://github.com/Fission-AI/OpenSpec"
SRC_URI="
	https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${PV}.tgz
		-> ${P}.tgz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/openspec-${PV}/openspec-${PV}-deps.tar.xz
"
S="${WORKDIR}/package"

src_unpack() {
	default_src_unpack
	cd "${T}" || die "Could not cd to temporary directory"
	unpack ${P}-deps.tar.xz
}

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ppc64 ~riscv ~x64-macos x86"
IUSE="bash-completion fish-completion zsh-completion"

RDEPEND=">=net-libs/nodejs-20.19.0[npm]"
BDEPEND="${RDEPEND}"

src_install() {
    export OPENSPEC_NO_COMPLETIONS=1
    npm \
        --offline \
        --verbose \
        --progress false \
        --foreground-scripts \
        --global \
        --prefix "${ED}/usr" \
        --cache "${T}/npm-cache" \
        install "${DISTDIR}/${P}.tgz" || die "npm install failed"

    if use bash-completion; then
        "${ED}/usr/bin/openspec" completion generate bash > openspec.bash ||
            die 'Unable to generate bash completions'
    fi
    if use fish-completion; then
        "${ED}/usr/bin/openspec" completion generate fish > openspec.fish ||
            die 'Unable to generate fish completions'
    fi
    if use zsh-completion; then
        "${ED}/usr/bin/openspec" completion generate zsh > openspec.zsh ||
            die 'Unable to generate zsh completions'
    fi

    use bash-completion &&
        newbashcomp openspec.bash openspec
    use fish-completion &&
        newfishcomp openspec.fish openspec.fish
    use zsh-completion &&
        newzshcomp openspec.zsh _openspec
}
