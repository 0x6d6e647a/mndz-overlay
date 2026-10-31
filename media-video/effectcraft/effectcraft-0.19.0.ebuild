# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-docpath]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/docpath'
	[craft-fonts-build]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/fonts-build'
	[craft-i18n]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/i18n'
	[craft-pdf]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/pdf'
	[craft-quit]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/quit'
	[craft-ui]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/ui'
	[craft-update]='https://github.com/storytold/craft-libs;04aa1703b32d299e54f78fcde4182f2b393a9116;craft-libs-%commit%/crates/update'
	[ecolor]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/ecolor'
	[eframe]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/eframe'
	[egui-wgpu]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-wgpu'
	[egui-winit]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-winit'
	[egui]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui'
	[egui_glow]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_glow'
	[egui_kittest]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_kittest'
	[emath]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/emath'
	[epaint]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint'
	[epaint_default_fonts]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint_default_fonts'
	[filmcraft-aac]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/aac'
	[filmcraft-ac3]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/ac3'
	[filmcraft-apv]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/apv'
	[filmcraft-av1]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/av1'
	[filmcraft-avi]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/avi'
	[filmcraft-bitstream]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/bitstream'
	[filmcraft-cfb]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/cfb'
	[filmcraft-codecs]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/codecs'
	[filmcraft-color]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/color'
	[filmcraft-dng]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/dng'
	[filmcraft-dnx]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/dnx'
	[filmcraft-frame]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/frame'
	[filmcraft-geom]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/geom'
	[filmcraft-h264]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/h264'
	[filmcraft-h264enc]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/h264enc'
	[filmcraft-hevc]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/hevc'
	[filmcraft-interchange]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/interchange'
	[filmcraft-isobmff]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/isobmff'
	[filmcraft-matroska]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/matroska'
	[filmcraft-media]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/media'
	[filmcraft-mpa]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/mpa'
	[filmcraft-mpeg2v]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/mpeg2v'
	[filmcraft-mpegts]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/mpegts'
	[filmcraft-mxf]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/mxf'
	[filmcraft-ogg]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/ogg'
	[filmcraft-opus]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/opus'
	[filmcraft-project]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/project'
	[filmcraft-prores]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/prores'
	[filmcraft-time]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/time'
	[filmcraft-vp8]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/vp8'
	[filmcraft-vp9]='https://github.com/storytold/filmcraft;09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5;filmcraft-%commit%/crates/vp9'
	[hayro-jbig2]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/vendor/hayro-jbig2'
	[hayro-syntax]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/vendor/hayro-syntax'
	[winit]='https://github.com/storytold/winit;a517b3846ee8457d84ee4975110bfda6797c44dc;winit-%commit%'
)

inherit cargo mndz-cargo desktop xdg

DESCRIPTION="Open-source native visual effects compositor"
HOMEPAGE="https://getartcraft.com/apps/effectcraft https://github.com/storytold/effectcraft"
SRC_URI="https://github.com/storytold/effectcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/effectcraft-${PV}/effectcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 BSD Boost-1.0 CDLA-Permissive-2.0 ISC MIT MPL-2.0
	Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+gui +cli +portal +X +wayland test"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# gui still needs xdg-open. The CLI links the GPU stack.
# v0.7.0 does not expose whisper, neural-voices, vaapi, or nvenc features.
DEPEND="
	gui? (
		media-libs/alsa-lib
	)
"
RDEPEND="
	media-libs/libglvnd
	media-libs/vulkan-loader
	gui? (
		media-libs/alsa-lib
		sys-apps/dbus
		x11-misc/xdg-utils
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

src_prepare() {
	default
	mndz-cargo_rewrite_patch_git_pins
}

src_compile() {
	local -a pkgs=()
	use gui && pkgs+=( -p effectcraft )
	use cli && pkgs+=( -p effectcraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude effectcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/effectcraft"
	use cli && dobin "$(cargo_target_dir)/effectcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/effectcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/effectcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.effectcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.effectcraft.mime.xml \
			ai.storyteller.effectcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.effectcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.effectcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.effectcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.effectcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.effectcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.effectcraft.svg
		fi
	fi
}
