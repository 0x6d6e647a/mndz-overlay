# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

BUN_PN="${PN//-bin/}"

DESCRIPTION="Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
HOMEPAGE="https://bun.sh"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="bash-completion cpu_flags_x86_avx2 debug fish-completion zsh-completion"

DEPEND="
    bash-completion? ( >=app-shells/bash-completion-2.0 )
    fish-completion? ( app-shells/fish )
    zsh-completion? ( app-shells/zsh )
"

bun_bin_filename_prefix() {
    local -r arch=$1
    local -r elibc=$2
    local -ir avx2=$3
    local -ir debug=$4

    local -a specifier

    # -- Add CPU architecture.
    case "${arch}" in
        amd64) specifier+=('x64')                ;;
        arm64) specifier+=('aarch64')            ;;
        *    ) die "Unsupported arch: '${arch}'" ;;
    esac  

    # -- Add libc type.
    case "${elibc}" in
        musl ) specifier+=('musl')                ;;
        glibc) :                                  ;;
        *    ) die "Unsupported libc: '${elibc}'" ;;
    esac

    # -- Add CPU features.
    (( avx2 == 0 )) &&
        specifier+=('baseline')

    # -- Add debug type.
    (( debug != 0 )) &&
        specifier+=('profile')

    # -- Construct string.
    suffix="$(IFS='-'; echo "${specifier[*]}")"
    echo "bun-linux-${suffix}"
}

BASE_URI="https://github.com/oven-sh/${BUN_PN}/releases/download/${BUN_PN}-v${PV}"
SRC_URI="
    amd64? (
        elibc_musl? (
            cpu_flags_x86_avx2? (
                debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 musl 1 1).zip
                        -> ${PN}-${PV}-amd64-musl-profile.zip
                )
                !debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 musl 1 0).zip
                        -> ${PN}-${PV}-amd64-musl.zip
                )
            )
            !cpu_flags_x86_avx2? (
                debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 musl 0 1).zip
                        -> ${PN}-${PV}-amd64-musl-baseline-profile.zip
                )
                !debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 musl 0 0).zip
                        -> ${PN}-${PV}-amd64-musl-baseline.zip
                )
            )
        )
        !elibc_musl? (
            cpu_flags_x86_avx2? (
                debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 glibc 1 1).zip
                        -> ${PN}-${PV}-amd64-profile.zip
                )
                !debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 glibc 1 0).zip
                        -> ${PN}-${PV}-amd64.zip
                )
            )
            !cpu_flags_x86_avx2? (
                debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 glibc 0 1).zip
                        -> ${PN}-${PV}-amd64-baseline-profile.zip
                )
                !debug? (
                    ${BASE_URI}/$(bun_bin_filename_prefix amd64 glibc 0 0).zip
                        -> ${PN}-${PV}-amd64-baseline.zip
                )
            )
        )
    )
    arm64? (
        elibc_musl? (
            debug? (
                ${BASE_URI}/$(bun_bin_filename_prefix arm64 musl 1 1).zip
                    -> ${PN}-${PV}-arm64-musl-profile.zip
            )
            !debug? (
                ${BASE_URI}/$(bun_bin_filename_prefix arm64 musl 1 0).zip
                    -> ${PN}-${PV}-arm64-musl.zip
            )
        )
        !elibc_musl? (
            debug? (
                ${BASE_URI}/$(bun_bin_filename_prefix arm64 glibc 1 1).zip
                    -> ${PN}-${PV}-arm64-profile.zip
            )
            !debug? (
                ${BASE_URI}/$(bun_bin_filename_prefix arm64 glibc 1 0).zip
                    -> ${PN}-${PV}-arm64.zip
            )
        )
    )
"

BDEPEND="app-arch/unzip"

QA_PREBUILT="*"

bun_bin_dirname() {
    local elibc
    if use elibc_glibc; then
        elibc='glibc'
    elif use elibc_musl; then
        elibc='musl'
    else
        die 'Unsupported libc'
    fi

    local -i avx2=0
    if use cpu_flags_x86_avx2 \
            || [[ "${ARCH}" == 'arm64' ]]; then
        (( avx2 = 1 ))
    fi

    local -i debug=0
    use debug &&
        (( debug = 1 ))

    bun_bin_filename_prefix "${ARCH}" "${elibc}" "${avx2}" "${debug}"
}

src_unpack() {
    unpack "${A}"
    mv "$(bun_bin_dirname)" "${P}"
}

src_compile() {
    local bun_bin='bun'
    if use debug; then
        bun_bin='bun-profile'
    fi

    if use bash-completion; then
        SHELL=bash "./${bun_bin}" completions > bun.bash ||
            die 'Unable to generate bash completions'
    fi

    if use fish-completion; then
        SHELL=fish "./${bun_bin}" completions > bun.fish ||
            die 'Unable to generate fish completions'
    fi

    if use zsh-completion; then
        SHELL=zsh "./${bun_bin}" completions > bun.zsh ||
            die 'Unable to generate zsh completions'
    fi
}

src_install() {
    exeinto /usr/bin

    if use debug; then
        doexe bun-profile
        dosym /usr/bin/bun-profile /usr/bin/bun
        dosym /usr/bin/bun-profile /usr/bin/bunx
    else
        doexe bun
        dosym /usr/bin/bun /usr/bin/bunx
    fi

    use bash-completion &&
        newbashcomp bun.bash "${BUN_PN}"

    use fish-completion &&
        newfishcomp bun.fish bun.fish

    use zsh-completion &&
        newzshcomp bun.zsh "_${BUN_PN}"
}
