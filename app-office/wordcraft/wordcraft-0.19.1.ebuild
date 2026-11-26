# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-atomic]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/atomic'
	[craft-cfb]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/cfb'
	[craft-codepage]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/codepage'
	[craft-dds]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/dds'
	[craft-doc-binary]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/doc-binary'
	[craft-docx]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/docx'
	[craft-drawingml]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/drawingml'
	[craft-flow]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/flow'
	[craft-font-catalog]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/font-catalog'
	[craft-font-store]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/font-store'
	[craft-fonts-build]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/fonts-build'
	[craft-html]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/html'
	[craft-i18n]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/i18n'
	[craft-image-codecs]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/image-codecs'
	[craft-jpeg]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/jpeg'
	[craft-latex]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/latex'
	[craft-markdown]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/markdown'
	[craft-math]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/math'
	[craft-mcp-server]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/mcp-server'
	[craft-metadata]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/metadata'
	[craft-metafile]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/metafile'
	[craft-mime]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/mime'
	[craft-odf]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/odf'
	[craft-ods]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/ods'
	[craft-offcrypto]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/offcrypto'
	[craft-opc]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/opc'
	[craft-pdf]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/pdf'
	[craft-print]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/print'
	[craft-proof]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/proof'
	[craft-rtf]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/rtf'
	[craft-sheet]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/sheet'
	[craft-ssip]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/ssip'
	[craft-tiff]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/tiff'
	[craft-ui]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/ui'
	[craft-update]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/update'
	[craft-web-api]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/web-api'
	[craft-web-host]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/web-host'
	[craft-window]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/window'
	[craft-winprint-gdi]='https://github.com/storytold/winprint.rs;64e7afd4d1483512385012c340ecaaaf0f3beb7f;winprint.rs-%commit%/crates/gdi'
	[craft-wordmodel]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/wordmodel'
	[craft-xls]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/xls'
	[craft-xlsx]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/xlsx'
	[craft-xml]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/xml'
	[craft-zip]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/crates/zip'
	[ecolor]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/ecolor'
	[eframe]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/eframe'
	[egui-wgpu]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-wgpu'
	[egui-winit]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-winit'
	[egui]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui'
	[egui_extras]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_extras'
	[egui_glow]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_glow'
	[egui_kittest]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_kittest'
	[emath]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/emath'
	[epaint]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint'
	[epaint_default_fonts]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint_default_fonts'
	[krilla]='https://github.com/storytold/craft-libs;93dac78c93a7f1fd66e2022edeb089233b1dc45a;craft-libs-%commit%/vendor/krilla'
	[winit]='https://github.com/storytold/winit;a517b3846ee8457d84ee4975110bfda6797c44dc;winit-%commit%'
	[winprint]='https://github.com/storytold/winprint.rs;8ae097ef941b432b0e7671b1ec3a506800e65e57;winprint.rs-%commit%'
)

inherit cargo mndz-cargo desktop xdg

DESCRIPTION="Open-source native word processor"
HOMEPAGE="https://getartcraft.com/apps/wordcraft https://github.com/storytold/wordcraft"
SRC_URI="https://github.com/storytold/wordcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/wordcraft-${PV}/wordcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD Boost-1.0
	CDLA-Permissive-2.0 IJG ISC MIT MPL-2.0 Unicode-3.0 ZLIB
"
# assets/fonts are OFL-1.1. assets/hyphenation embeds the public-domain
# Moby Hyphenator II list and patterns trained from it.
LICENSE+="OFL-1.1 public-domain CC0-1.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
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
BDEPEND="media-fonts/craft-fonts:="

src_prepare() {
	default
	mndz-cargo_rewrite_patch_git_pins
}

src_compile() {
	export CRAFT_FONTS_DIR=/usr/share/craft-fonts
	export CRAFT_FONTS_REQUIRED=1
	local -a pkgs=()
	use gui && pkgs+=( -p wordcraft )
	use cli && pkgs+=( -p wordcraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude wordcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/wordcraft"
	use cli && dobin "$(cargo_target_dir)/wordcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/wordcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/wordcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.wordcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.wordcraft.mime.xml \
			ai.storyteller.wordcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.wordcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.wordcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.wordcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.wordcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.wordcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.wordcraft.svg
		fi
	fi
}
