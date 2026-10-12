# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

inherit cargo xdg

DESCRIPTION="Open-source native PDF tool"
HOMEPAGE="https://getartcraft.com/apps/pdfcraft https://github.com/storytold/pdfcraft"
SRC_URI="https://github.com/storytold/pdfcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/pdfcraft-${PV}/pdfcraft-${PV}-crates.tar.xz"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 BSD Boost-1.0 ISC MIT OFL-1.1 UbuntuFontLicense-1.0
	Unicode-3.0 ZLIB
"
# assets/fonts and craft-fonts are OFL-1.1. assets/icons embeds Lucide (ISC).
# vendor/hayro-interpret embeds a CC0 ICC profile and PDFium Foxit fonts (BSD).
LICENSE+="OFL-1.1 ISC CC0-1.0 BSD"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86 ~arm ~arm64 ~ppc64 ~loong ~riscv ~sparc ~s390"
IUSE="+gui +cli +portal +X +wayland test cups"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# gui still needs xdg-open.
BDEPEND="
	dev-build/cmake
	dev-lang/nasm
	media-fonts/craft-fonts:=
"
RDEPEND="
	cups? ( net-print/cups )
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

src_compile() {
	export CRAFT_FONTS_DIR=/usr/share/craft-fonts
	export CRAFT_FONTS_REQUIRED=1
	local -a pkgs=()
	use gui && pkgs+=( -p pdfcraft )
	use cli && pkgs+=( -p pdfcraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude pdfcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/pdfcraft"
	use cli && dobin "$(cargo_target_dir)/pdfcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/pdfcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/pdfcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.pdfcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.pdfcraft.mime.xml \
			ai.storyteller.pdfcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.pdfcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.pdfcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.pdfcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.pdfcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.pdfcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.pdfcraft.svg
		fi
	fi
}
