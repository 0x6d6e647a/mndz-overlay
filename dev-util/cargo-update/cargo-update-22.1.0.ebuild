# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.86.0"

CRATES=""

inherit cargo

DESCRIPTION="A cargo subcommand for checking and applying updates to installed executables"
HOMEPAGE="https://github.com/nabijaczleweli/cargo-update"
SRC_URI="https://crates.io/api/v1/crates/cargo-update/${PV}/download -> cargo-update-${PV}.crate"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/cargo-update-${PV}/cargo-update-${PV}-crates.tar.xz"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	MIT Unicode-3.0
	|| ( Apache-2.0 Boost-1.0 )
"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+system-openssl +system-libgit2 +system-libcurl +libsecret +man test"
REQUIRED_USE="system-libcurl? ( system-openssl )"
RESTRICT="!test? ( test )"

DEPEND="
	system-openssl? ( dev-libs/openssl:= )
	system-libgit2? ( >=dev-libs/libgit2-1.9.0 <dev-libs/libgit2-1.10:= )
	system-libcurl? ( net-misc/curl[http2] )
	net-libs/libssh2:=
	sys-libs/zlib:=
"
RDEPEND="
	${DEPEND}
	libsecret? ( app-crypt/libsecret )
"
BDEPEND="
	virtual/pkgconfig
	dev-build/cmake
	man? ( app-text/ronn-ng )
	!system-openssl? ( dev-lang/perl )
"

# rust does not use *FLAGS from make.conf, silence portage warning
# /usr/bin/cargo-install-update
# /usr/bin/cargo-install-update-config
QA_FLAGS_IGNORED="usr/bin/cargo-install-update usr/bin/cargo-install-update-config"

src_configure() {
	local myfeatures=(
		$(usev !system-openssl vendored-openssl)
		$(usev !system-libgit2 vendored-libgit2)
		$(usev !system-libcurl vendored-libcurl)
	)
	export LIBSSH2_SYS_USE_PKG_CONFIG=1
	if use system-openssl; then
		export OPENSSL_NO_VENDOR=1
	fi
	if use system-libgit2; then
		export LIBGIT2_NO_VENDOR=1
	fi
	cargo_src_configure
}

src_test() {
	cargo_src_test
}

src_install() {
	cargo_src_install
	if use man; then
		export HOME="${T}"
		export RUBYOPT="-Eutf-8:utf-8"
		ronn -r man/*.md || die
		doman man/*.1 || die
	fi
}
