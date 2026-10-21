# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Kiro IDE desktop editor (prebuilt binary)"
HOMEPAGE="https://kiro.dev/"
SRC_URI="
	amd64? (
		https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/${PV}/tar/kiro-ide-${PV}-stable-linux-x64.tar.gz
	)
	arm64? (
		https://prod.download.desktop.kiro.dev/releases/stable/linux-arm64/signed/${PV}/tar/kiro-ide-${PV}-stable-linux-arm64.tar.gz
	)
"

S="${WORKDIR}/Kiro"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="+command-sandbox microsoft-auth"
RESTRICT="bindist mirror strip"

# * covers the installed tree, including nested ELF files.
QA_PREBUILT="usr/share/kiro/*"

RDEPEND="
	>=sys-libs/glibc-2.34
	app-accessibility/at-spi2-core
	app-crypt/libsecret
	app-shells/bash-completion
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/libpulse
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libxkbfile
	x11-libs/libXrandr
	x11-libs/pango
	command-sandbox? (
		net-misc/socat
		sys-apps/bubblewrap
	)
	microsoft-auth? (
		dev-libs/openssl
		net-libs/libsoup:3
		net-libs/webkit-gtk:4.1
		net-misc/curl
		sys-apps/util-linux
	)
"

src_prepare() {
	default

	# Drop Windows PE addons. The set is whatever file reports, including
	# PowerShell assemblies and the win32 debug tokens.
	local f desc
	while IFS= read -r -d '' f; do
		desc=$(file -b -- "${f}") || die "file ${f}"
		case ${desc} in
			PE32*)
				rm -f -- "${f}" || die "rm ${f}"
				;;
		esac
	done < <(find . -type f -print0)

	if ! use microsoft-auth; then
		rm -rf resources/app/extensions/microsoft-authentication \
			|| die "rm microsoft-authentication"
	fi
}

src_install() {
	# doins drops executable bits on the Electron tree.
	dodir /usr/share/kiro
	cp -a . "${ED}/usr/share/kiro/" || die "cp Kiro tree"

	# Keep the renderer helper unprivileged. A setuid bit in the tarball
	# must not survive. A host without user namespaces needs a hand-made
	# mode 4755 helper; this package does not chmod it.
	fperms 0755 /usr/share/kiro/chrome-sandbox

	dosym /usr/share/kiro/bin/kiro /usr/bin/kiro

	newicon -s 1024 resources/app/resources/linux/code.png kiro.png

	cat > "${T}/kiro.desktop" <<-EOF || die "desktop entry"
		[Desktop Entry]
		Name=Kiro
		Comment=Kiro IDE
		GenericName=Text Editor
		Exec=/usr/bin/kiro --ozone-platform-hint=auto %F
		Icon=kiro
		Type=Application
		StartupNotify=true
		Categories=Development;IDE;TextEditor;
		MimeType=x-scheme-handler/kiro;
	EOF
	domenu "${T}/kiro.desktop"

	insinto /usr/share/bash-completion/completions
	newins resources/completions/bash/kiro kiro
	insinto /usr/share/zsh/site-functions
	doins resources/completions/zsh/_kiro

	cat > "${T}/policy.json" <<-EOF || die "policy.json"
		{"UpdateMode":"none"}
	EOF
	insinto /etc/kiro
	doins "${T}/policy.json"
}

pkg_postinst() {
	elog "UpdateMode is none"
	elog "The command sandbox stays off until the user enables it and is Unavailable without bubblewrap"
	elog "chrome-sandbox stays mode 0755 unless the operator sets mode 4755 on a host without user namespaces"
}
