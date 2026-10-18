# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-docpath]='https://github.com/storytold/craft-libs;82a24b006eefa036b43c09a67fb9a3fbd17ffe63;craft-libs-%commit%/crates/docpath'
	[craft-ui]='https://github.com/storytold/craft-libs;5c874d51eeb3de70e735c8ce87a59a7dedd47675;craft-libs-%commit%/crates/ui'
)

inherit cargo desktop xdg

DESCRIPTION="Open-source native photo developer"
HOMEPAGE="https://getartcraft.com/apps/lightcraft https://github.com/storytold/lightcraft"
SRC_URI="https://github.com/storytold/lightcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/lightcraft-${PV}/lightcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 BSD Boost-1.0 CDLA-Permissive-2.0 IJG ISC MIT
	MPL-2.0 UoI-NCSA OFL-1.1 UbuntuFontLicense-1.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+gui +cli +portal +X +wayland test +heif rawnind-model"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# gui still needs xdg-open.
RDEPEND="
	gui? (
		sys-apps/dbus
		x11-misc/xdg-utils
		media-libs/libglvnd
		media-libs/vulkan-loader
		x11-libs/libxkbcommon
		portal? ( sys-apps/xdg-desktop-portal )
		!portal? ( gnome-extra/zenity )
	)
	X? (
		x11-libs/libX11
		x11-libs/libXcursor
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libxkbcommon[X]
	)
	wayland? (
		dev-libs/wayland
	)
"

src_compile() {
	local -a pkgs=() args=()
	use gui && pkgs+=( -p lightcraft )
	use cli && pkgs+=( -p lightcraft-cli )
	use heif && args+=( --features heif )
	use rawnind-model && args+=( --features rawnind-model )
	cargo_src_compile "${pkgs[@]}" "${args[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude lightcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/lightcraft"
	use cli && dobin "$(cargo_target_dir)/lightcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/lightcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/lightcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.lightcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.lightcraft.mime.xml \
			ai.storyteller.lightcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.lightcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.lightcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.lightcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.lightcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.lightcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.lightcraft.svg
		fi
	fi
}
