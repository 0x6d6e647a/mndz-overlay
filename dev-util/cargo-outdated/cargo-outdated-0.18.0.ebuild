# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.84.0"

CRATES=""

inherit cargo

DESCRIPTION="A cargo subcommand for displaying when Rust dependencies are out of date"
HOMEPAGE="https://github.com/kbknapp/cargo-outdated"
SRC_URI="https://crates.io/api/v1/crates/cargo-outdated/${PV}/download -> cargo-outdated-${PV}.crate"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/cargo-outdated-${PV}/cargo-outdated-${PV}-crates.tar.xz"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" Apache-2.0 BSD-2 BSD ISC MIT MPL-2.0 Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+system-openssl +system-libcurl +system-libgit2 +system-libssh2 +system-zlib +system-sqlite +libsecret test"
REQUIRED_USE="
	!system-openssl? ( !system-libcurl !system-libgit2 !system-libssh2 )
	!system-libcurl? ( !system-openssl )
	system-libgit2? ( system-libssh2 )
	!system-zlib? ( !system-libcurl )
"
RESTRICT="!test? ( test )"

DEPEND="
	system-openssl? ( dev-libs/openssl:= )
	system-libcurl? ( net-misc/curl[http2,ssl] )
	system-libgit2? ( >=dev-libs/libgit2-1.9.2 <dev-libs/libgit2-1.10:= )
	system-libssh2? ( net-libs/libssh2:= )
	system-zlib? ( sys-libs/zlib:= )
	system-sqlite? ( dev-db/sqlite:3 )
"
RDEPEND="
	${DEPEND}
	libsecret? ( app-crypt/libsecret )
"
BDEPEND="
	virtual/pkgconfig
	!system-openssl? ( dev-lang/perl )
"

# rust does not use *FLAGS from make.conf, silence portage warning
# /usr/bin/cargo-outdated
QA_FLAGS_IGNORED="usr/bin/cargo-outdated"

src_configure() {
	local myfeatures=(
		$(usev !system-openssl vendored-openssl)
		$(usev !system-libcurl cargo/all-static)
		$(usev !system-libgit2 cargo/vendored-libgit2)
	)
	if use system-openssl; then
		export OPENSSL_NO_VENDOR=1
	fi
	if use system-libgit2; then
		export LIBGIT2_NO_VENDOR=1
	fi
	if use system-libssh2; then
		export LIBSSH2_SYS_USE_PKG_CONFIG=1
	fi
	if use system-sqlite; then
		export LIBSQLITE3_SYS_USE_PKG_CONFIG=1
	fi
	if ! use system-zlib; then
		export LIBZ_SYS_STATIC=1
	fi
	cargo_src_configure
}

src_test() {
	cargo_src_test
}

src_install() {
	cargo_src_install
}
