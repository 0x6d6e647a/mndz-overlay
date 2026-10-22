# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

CRATES=""

declare -A GIT_CRATES=(
	[craft-docpath]='https://github.com/storytold/craft-libs;82a24b006eefa036b43c09a67fb9a3fbd17ffe63;craft-libs-%commit%/crates/docpath'
	[craft-ui]='https://github.com/storytold/craft-libs;5c874d51eeb3de70e735c8ce87a59a7dedd47675;craft-libs-%commit%/crates/ui'
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
	CDLA-Permissive-2.0 ISC MIT MPL-2.0 OFL-1.1 UbuntuFontLicense-1.0
	Unicode-3.0 ZLIB
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
