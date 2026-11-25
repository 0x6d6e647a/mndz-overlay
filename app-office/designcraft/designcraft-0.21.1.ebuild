# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-atomic]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/atomic'
	[craft-cfb]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/cfb'
	[craft-cms]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/cms'
	[craft-codepage]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/codepage'
	[craft-csv]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/csv'
	[craft-dds]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/dds'
	[craft-designcraft-format]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/designcraft-format'
	[craft-dialogs]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/dialogs'
	[craft-docpath]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/docpath'
	[craft-document-bundle]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/document-bundle'
	[craft-docx]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/docx'
	[craft-drawingml]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/drawingml'
	[craft-eps]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/eps'
	[craft-epub]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/epub'
	[craft-file-formats]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/file-formats'
	[craft-fonts-build]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/fonts-build'
	[craft-i18n]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/i18n'
	[craft-idml]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/idml'
	[craft-image-codecs]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/image-codecs'
	[craft-indd]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/indd'
	[craft-jpeg]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/jpeg'
	[craft-keymap]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/keymap'
	[craft-math]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/math'
	[craft-mcp-server]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/mcp-server'
	[craft-metadata]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/metadata'
	[craft-mime]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/mime'
	[craft-offcrypto]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/offcrypto'
	[craft-opc]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/opc'
	[craft-pdf]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/pdf'
	[craft-pptx]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/pptx'
	[craft-prepress]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/prepress'
	[craft-print]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/print'
	[craft-ps]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/ps'
	[craft-psd]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/psd'
	[craft-rtf]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/rtf'
	[craft-sheet]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/sheet'
	[craft-svg]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/svg'
	[craft-tiff]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/tiff'
	[craft-ui]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/ui'
	[craft-update]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/update'
	[craft-window]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/window'
	[craft-winprint-gdi]='https://github.com/storytold/winprint.rs;64e7afd4d1483512385012c340ecaaaf0f3beb7f;winprint.rs-%commit%/crates/gdi'
	[craft-wordmodel]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/wordmodel'
	[craft-xlsx]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/xlsx'
	[craft-xml]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/xml'
	[craft-zip]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/crates/zip'
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
	[hayro-cmap]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro-cmap'
	[hayro-interpret]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro-interpret'
	[hayro-jbig2]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro-jbig2'
	[hayro-postscript]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro-postscript'
	[hayro-syntax]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro-syntax'
	[hayro]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/hayro'
	[indd]='https://github.com/storytold/indd-utils;7f3060e5bce78d21ea70e0d5eacb96edce15dfbe;indd-utils-%commit%'
	[krilla]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/krilla'
	[linesweeper]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/linesweeper'
	[vectorcraft-geom]='https://github.com/storytold/vectorcraft;6b3a6b8788ebcb420d69449199cbdf323888d27e;vectorcraft-%commit%/crates/geom'
	[vectorcraft-pathops]='https://github.com/storytold/vectorcraft;6b3a6b8788ebcb420d69449199cbdf323888d27e;vectorcraft-%commit%/crates/pathops'
	[vello_common]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/vello_common'
	[vello_cpu]='https://github.com/storytold/craft-libs;33be35625e252cc4f06aa375b3b428521faea37d;craft-libs-%commit%/vendor/vello_cpu'
	[winit]='https://github.com/storytold/winit;a517b3846ee8457d84ee4975110bfda6797c44dc;winit-%commit%'
	[winprint]='https://github.com/storytold/winprint.rs;8ae097ef941b432b0e7671b1ec3a506800e65e57;winprint.rs-%commit%'
)

inherit cargo mndz-cargo desktop xdg

DESCRIPTION="Open-source native page layout"
HOMEPAGE="https://getartcraft.com/apps/designcraft https://github.com/storytold/designcraft"
SRC_URI="https://github.com/storytold/designcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/designcraft-${PV}/designcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 BSD Boost-1.0 CDLA-Permissive-2.0 IJG ISC MIT
	MPL-2.0 Unicode-3.0 ZLIB
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
