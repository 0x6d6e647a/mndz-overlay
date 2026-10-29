# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-docpath]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/docpath'
	[craft-fonts-build]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/fonts-build'
	[craft-i18n]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/i18n'
	[craft-media]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/media'
	[craft-ui]='https://github.com/storytold/craft-libs;92d392cff132eaf53e13afff77f38b5c11b73aa0;craft-libs-%commit%/crates/ui'
	[ecolor]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/ecolor'
	[egui-wgpu]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-wgpu'
	[egui-winit]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui-winit'
	[egui_glow]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_glow'
	[egui_kittest]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/egui_kittest'
	[emath]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/emath'
	[epaint]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint'
	[epaint_default_fonts]='https://github.com/storytold/egui;6d518fc799681571963842f95b55a6b68431b15a;egui-%commit%/crates/epaint_default_fonts'
	[winit]='https://github.com/storytold/winit;a517b3846ee8457d84ee4975110bfda6797c44dc;winit-%commit%'
)

inherit cargo mndz-cargo desktop xdg

DESCRIPTION="Open-source native video editor"
HOMEPAGE="https://getartcraft.com/apps/filmcraft https://github.com/storytold/filmcraft"
SRC_URI="https://github.com/storytold/filmcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/filmcraft-${PV}/filmcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD Boost-1.0
	CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+gui +cli +portal +X +wayland test whisper vaapi nvenc"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# gui still needs xdg-open. The CLI links the GPU stack.
# v0.5.0 has no neural-voices cargo feature, so that flag is omitted.
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
	vaapi? ( media-libs/libva )
	nvenc? ( x11-drivers/nvidia-drivers )
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
	local -a pkgs=() args=()
	use gui && pkgs+=( -p filmcraft )
	use cli && pkgs+=( -p filmcraft-cli )
	use whisper && args+=( --features whisper )
	cargo_src_compile "${pkgs[@]}" "${args[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude filmcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/filmcraft"
	use cli && dobin "$(cargo_target_dir)/filmcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/filmcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/filmcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.filmcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.filmcraft.mime.xml \
			ai.storyteller.filmcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.filmcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.filmcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.filmcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.filmcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.filmcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.filmcraft.svg
		fi
	fi
}
