# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-docpath]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/docpath'
	[craft-fonts-build]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/fonts-build'
	[craft-i18n]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/i18n'
	[craft-jpeg]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/jpeg'
	[craft-pcraft-format]='https://github.com/storytold/craft-libs;b8f7d93b00dfb8f172938f3d2d796ae62dcfe123;craft-libs-%commit%/crates/pcraft-format'
	[craft-pdf]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/pdf'
	[craft-print]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/print'
	[craft-ui]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/ui'
	[craft-update]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/crates/update'
	[craft-winprint-gdi]='https://github.com/storytold/winprint.rs;64e7afd4d1483512385012c340ecaaaf0f3beb7f;winprint.rs-%commit%/crates/gdi'
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
	[hayro-interpret]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/vendor/hayro-interpret'
	[hayro-jbig2]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/vendor/hayro-jbig2'
	[hayro-syntax]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/vendor/hayro-syntax'
	[hayro]='https://github.com/storytold/craft-libs;1b34eba41e62138fc2438d2734523b302840b45d;craft-libs-%commit%/vendor/hayro'
	[winit]='https://github.com/storytold/winit;a517b3846ee8457d84ee4975110bfda6797c44dc;winit-%commit%'
	[winprint]='https://github.com/storytold/winprint.rs;51934db382f225454cf152a8657eb03789be63c4;winprint.rs-%commit%'
)

inherit cargo mndz-cargo desktop xdg

DESCRIPTION="Open-source native image editor"
HOMEPAGE="https://getartcraft.com/apps/photocraft https://github.com/storytold/photocraft"
SRC_URI="https://github.com/storytold/photocraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/photocraft-${PV}/photocraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD Boost-1.0
	CDLA-Permissive-2.0 IJG ISC MIT MPL-2.0 UoI-NCSA Unicode-3.0 ZLIB
"
LICENSE+="OFL-1.1 ISC CC0-1.0 SCOWL"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+gui +cli +portal +X +wayland test"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# apps/photocraft does not depend on the open crate. gui still needs xdg-open.
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

src_prepare() {
	default
	mndz-cargo_rewrite_patch_git_pins
}

src_compile() {
	local -a pkgs=()
	use gui && pkgs+=( -p photocraft )
	use cli && pkgs+=( -p photocraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude photocraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/photocraft"
	use cli && dobin "$(cargo_target_dir)/photocraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/photocraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/photocraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.photocraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.photocraft.mime.xml \
			ai.storyteller.photocraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.photocraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.photocraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.photocraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.photocraft.png"
		done
		doicon -s scalable \
			assets/app-icon/hicolor/scalable/apps/ai.storyteller.photocraft.svg
	fi
}
