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

DESCRIPTION="Open-source native audio workstation"
HOMEPAGE="https://getartcraft.com/apps/soundcraft https://github.com/storytold/soundcraft"
SRC_URI="https://github.com/storytold/soundcraft/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/soundcraft-${PV}/soundcraft-${PV}-crates.tar.xz"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD Boost-1.0 ISC MIT MPL-2.0 OFL-1.1
	UbuntuFontLicense-1.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+gui +cli +portal +X +wayland test"
REQUIRED_USE="|| ( gui cli ) gui? ( || ( X wayland ) )"
RESTRICT="!test? ( test )"

# gui still needs xdg-open.
DEPEND="
	gui? (
		media-libs/alsa-lib
	)
"
RDEPEND="
	gui? (
		media-libs/alsa-lib
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

	# The VST3 test loads the first libz.so.1 it finds and expects a missing
	# GetPluginFactory. Gentoo multilib has ELF32 at /usr/lib and ELF64 in lib64,
	# so the original order dlopens the 32-bit library and dies with ELFCLASS32.
	local test_rs="${S}/crates/vst3-host/src/lib.rs"
	local old='"/lib/x86_64-linux-gnu/libz.so.1", "/usr/lib/libz.so.1", "/lib64/libz.so.1"'
	local new='"/lib/x86_64-linux-gnu/libz.so.1", "/usr/lib64/libz.so.1", "/lib64/libz.so.1", "/usr/lib/libz.so.1"'
	grep -q -F "${old}" "${test_rs}" ||
		die "libz probe missing from ${test_rs}; update src_prepare"
	sed -i "s|${old}|${new}|" "${test_rs}" || die
}

src_compile() {
	local -a pkgs=()
	use gui && pkgs+=( -p soundcraft )
	use cli && pkgs+=( -p soundcraft-cli )
	cargo_src_compile "${pkgs[@]}"
}

src_test() {
	# cargo_src_test would forward a package selection and drop the library crates.
	cargo_src_test --workspace --exclude soundcraft-web --exclude xtask
}

src_install() {
	# cargo install rejects -p. src_compile already built the selected bins.
	use gui && dobin "$(cargo_target_dir)/soundcraft"
	use cli && dobin "$(cargo_target_dir)/soundcraft-cli"

	use gui && QA_FLAGS_IGNORED+=" usr/bin/soundcraft"
	use cli && QA_FLAGS_IGNORED+=" usr/bin/soundcraft-cli"

	if use gui; then
		domenu packaging/linux/ai.storyteller.soundcraft.desktop
		insinto /usr/share/mime/packages
		newins packaging/linux/ai.storyteller.soundcraft.mime.xml \
			ai.storyteller.soundcraft.xml

		local rel_date
		if [[ -n ${SOURCE_DATE_EPOCH} ]]; then
			rel_date=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d) || die
		else
			rel_date=$(date -u +%Y-%m-%d) || die
		fi
		sed -e "s/@VERSION@/${PV}/g" -e "s/@DATE@/${rel_date}/g" \
			packaging/linux/ai.storyteller.soundcraft.metainfo.xml.in \
			> "${T}"/ai.storyteller.soundcraft.metainfo.xml || die
		insinto /usr/share/metainfo
		doins "${T}"/ai.storyteller.soundcraft.metainfo.xml

		local sz
		for sz in 16 24 32 48 64 128 256 512; do
			doicon -s "${sz}" \
				"assets/app-icon/hicolor/${sz}x${sz}/apps/ai.storyteller.soundcraft.png"
		done
		if [[ -f assets/app-icon/hicolor/scalable/apps/ai.storyteller.soundcraft.svg ]]; then
			doicon -s scalable \
				assets/app-icon/hicolor/scalable/apps/ai.storyteller.soundcraft.svg
		fi
	fi
}
