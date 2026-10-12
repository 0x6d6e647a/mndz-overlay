# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

inherit cargo xdg

DESCRIPTION="Open-source native page layout"
HOMEPAGE="https://getartcraft.com/apps/designcraft https://github.com/storytold/designcraft"
SRC_URI="https://github.com/storytold/designcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/designcraft-${PV}/designcraft-${PV}-crates.tar.xz"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 BSD Boost-1.0 ISC MIT MPL-2.0 OFL-1.1
	UbuntuFontLicense-1.0 Unicode-3.0 ZLIB
"
# assets/fonts are OFL-1.1. assets/hyphenation embeds the public-domain
# Moby Hyphenator II list and patterns trained from it.
LICENSE+="OFL-1.1 public-domain CC0-1.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86 ~arm ~arm64 ~ppc64 ~loong ~riscv ~sparc ~s390"
IUSE="+gui +cli +portal +X +wayland test"
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
		!portal? ( gnome-base/zenity )
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
BDEPEND="media-fonts/craft-fonts:="

src_compile() {
	export CRAFT_FONTS_DIR=/usr/share/craft-fonts
	export CRAFT_FONTS_REQUIRED=1
	local -a pkgs=()
	use gui && pkgs+=( -p designcraft )
	use cli && pkgs+=( -p designcraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude designcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/designcraft"
	use cli && dobin "$(cargo_target_dir)/designcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/designcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/designcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.designcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.designcraft.mime.xml \
			ai.storyteller.designcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.designcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.designcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.designcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.designcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.designcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.designcraft.svg
		fi
	fi
}
