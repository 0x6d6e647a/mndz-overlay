# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="Grok Bot desktop agent (prebuilt binary)"
HOMEPAGE="https://x.ai/bot"

# Single assignment. overlay-manager rewrites this on a GitMv bump.
GROK_BOT_COMMIT="47a9d1df3a7d37aaa53d206ab2d1f9159a336223"

SRC_URI="
	amd64? ( https://downloads.cursor.com/grokbot/stable/${GROK_BOT_COMMIT}/linux/x64/grok-bot_${PV}_amd64.deb )
	arm64? ( https://downloads.cursor.com/grokbot/stable/${GROK_BOT_COMMIT}/linux/arm64/grok-bot_${PV}_arm64.deb )
"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="+wayland +pulseaudio +libnotify suid apparmor"
RESTRICT="bindist mirror strip"

# Quoted so the space survives Portage shlex splitting. * covers the tree.
QA_PREBUILT='"opt/Grok Bot/*"'

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
	libnotify? ( x11-libs/libnotify )
	pulseaudio? ( media-libs/libpulse )
	wayland? ( dev-libs/wayland )
"

src_install() {
	# unpacker extracts the deb and does not run its maintainer scripts.
	dodir /opt
	cp -a "opt/Grok Bot" "${ED}/opt/" || die

	fperms 0755 "/opt/Grok Bot/grok-bot" "/opt/Grok Bot/chrome_crashpad_handler" || die
	if use suid; then
		fperms 4755 "/opt/Grok Bot/chrome-sandbox" || die
	else
		fperms 0755 "/opt/Grok Bot/chrome-sandbox" || die
	fi

	dosym "/opt/Grok Bot/grok-bot" /usr/bin/grok-bot

	insinto /usr/share/applications
	doins usr/share/applications/grok-bot.desktop

	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	if use apparmor; then
		insinto /etc/apparmor.d
		newins "opt/Grok Bot/resources/apparmor-profile" grok-bot
	fi
}
