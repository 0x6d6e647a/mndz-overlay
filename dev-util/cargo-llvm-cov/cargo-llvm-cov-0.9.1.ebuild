# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.87.0"

CRATES=""

declare -A GIT_CRATES=(
	[test-helper]='https://github.com/taiki-e/test-helper;82e3b012a49fb16587e165986674290ef682a5b0;test-helper-%commit%'
)

inherit cargo

DESCRIPTION="Cargo subcommand for LLVM source-based code coverage"
HOMEPAGE="https://github.com/taiki-e/cargo-llvm-cov"
SRC_URI="https://github.com/taiki-e/cargo-llvm-cov/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/cargo-llvm-cov-${PV}/cargo-llvm-cov-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( Apache-2.0 MIT )"
# Dependent crate licenses
LICENSE+=" Apache-2.0 MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="llvm-core/llvm"
BDEPEND="test? ( dev-vcs/git )"

# The built binary is not a compiler input. The wrapper is a shell script.
QA_FLAGS_IGNORED="usr/libexec/cargo-llvm-cov/cargo-llvm-cov"

src_prepare() {
	default

	# cargo.eclass patches the GIT_CRATES URL without the .git suffix.
	# Cargo.toml names https://github.com/taiki-e/test-helper.git, so that
	# patch does not apply and an offline build tries to clone the repo.
	local uri commit dir
	IFS=';' read -r uri commit dir <<< "${GIT_CRATES[test-helper]}"
	[[ -n ${commit} ]] || die "test-helper GIT_CRATES entry has no commit"
	: "${dir:=test-helper-%commit%}"
	local needle="git = \"https://github.com/taiki-e/test-helper.git\", rev = \"${commit}\""
	local path="${WORKDIR}/${dir//%commit%/${commit}}"
	grep -F -q "${needle}" Cargo.toml || die "test-helper git pin not found in Cargo.toml"
	sed -i -e "s|${needle}|path = \"${path}\"|" Cargo.toml || die
	grep -F -q "path = \"${path}\"" Cargo.toml || die "test-helper path rewrite failed"
}

src_test() {
	git init || die
	git add -A || die
	git -c user.name="Portage" -c user.email="portage@localhost" \
		commit -m "Track test fixtures" || die
	. "${FILESDIR}/cargo-llvm-cov" || die
	cargo_llvm_cov_lookup || die
	local CARGO_SKIP_TESTS=( trybuild ui_test )
	cargo_src_test
}

src_install() {
	# /usr/libexec/cargo-llvm-cov/cargo-llvm-cov
	exeinto /usr/libexec/cargo-llvm-cov
	newexe "$(cargo_target_dir)/cargo-llvm-cov" cargo-llvm-cov
	# /usr/bin/cargo-llvm-cov
	dobin "${FILESDIR}/cargo-llvm-cov"
}
