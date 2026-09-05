# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.74.0"

CRATES=""

inherit cargo

DESCRIPTION="Visual binary file diff using sequence alignment"
HOMEPAGE="https://github.com/8051Enthusiast/biodiff"
SRC_URI="https://crates.io/api/v1/crates/biodiff/${PV}/download -> biodiff-${PV}.crate"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/biodiff-${PV}/biodiff-${PV}-crates.tar.xz"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" Apache-2.0 BSD ISC MIT MPL-2.0 Unicode-DFS-2016"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+wfa2 test"
RESTRICT="!test? ( test )"

RDEPEND=""
BDEPEND="wfa2? ( dev-build/cmake llvm-core/clang:21 )"

# rust does not use *FLAGS from make.conf, silence portage warning
QA_FLAGS_IGNORED="usr/bin/biodiff"

src_configure() {
	# wfa2 (default): upstream default feature set, bundled WFA2-lib through
	# the -sys crate. Without wfa2: pure-Rust RustBio alignment backend.
	local myfeatures=( $(usex wfa2 '' '--no-default-features') )
	if use wfa2; then
		# The 1.2.0-era -sys crate generates bindings with bindgen 0.69,
		# which emits opaque structs against libclang 22; point bindgen's
		# runtime discovery at the pinned compatible libclang slot.
		export LIBCLANG_PATH="${EPREFIX}/usr/lib/llvm/21/lib64"
	fi
	cargo_src_configure "${myfeatures[@]}"
}
