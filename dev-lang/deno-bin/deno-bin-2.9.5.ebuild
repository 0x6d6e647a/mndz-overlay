# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DENO_PN="${PN//-bin/}"

DESCRIPTION="A modern runtime for JavaScript and TypeScript"
HOMEPAGE="https://deno.com"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="bash-completion fish-completion zsh-completion"

DEPEND="
    bash-completion? ( >=app-shells/bash-completion-2.0 )
    fish-completion? ( app-shells/fish )
    zsh-completion? ( app-shells/zsh )
"

BASE_URI="https://github.com/denoland/${DENO_PN}/releases/download/v${PV}"
SRC_URI="
    amd64? (
        ${BASE_URI}/${DENO_PN}-x86_64-unknown-linux-gnu.zip
            -> ${PN}-${PV}-amd64.zip
    )
    arm64? (
        ${BASE_URI}/${DENO_PN}-aarch64-unknown-linux-gnu.zip
            -> ${PN}-${PV}-arm64.zip
    )
"

BDEPEND="app-arch/unzip"

QA_PREBUILT="*"

S="${WORKDIR}"

src_compile() {
    if use bash-completion; then
        ./deno completions bash > deno.bash ||
            die 'Unable to generate bash completions'
    fi

    if use fish-completion; then
        ./deno completions fish > deno.fish ||
            die 'Unable to generate fish completions'
    fi

    if use zsh-completion; then
        ./deno completions zsh > deno.zsh ||
            die 'Unable to generate zsh completions'
    fi
}

src_install() {
    exeinto /usr/bin

    doexe deno

    use bash-completion &&
        newbashcomp deno.bash "${DENO_PN}"

    use fish-completion &&
        newfishcomp deno.fish deno.fish

    use zsh-completion &&
        newzshcomp deno.zsh "_${DENO_PN}"
}
