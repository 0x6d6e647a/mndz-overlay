# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Project-local Common Lisp library installer"
HOMEPAGE="https://github.com/fukamachi/qlot"
SRC_URI="https://github.com/fukamachi/qlot/releases/download/${PV}/qlot-${PV}.tar.gz"
S="${WORKDIR}/qlot"

LICENSE="MIT"
# qlot LICENSE.txt, vendored quicklisp-client, and every
# .bundle-libs/software/* project in the GitHub release tarball.
LICENSE+="
	BSD BSD-2 MIT MPL-2.0 public-domain ZLIB
"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~riscv ~sparc ~x86 ~x64-macos"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-lisp/sbcl
	dev-libs/openssl:=
	dev-vcs/git
"
BDEPEND="${RDEPEND}"

qlot_sandbox_env() {
	# Portage does not source /etc/env.d/50sbcl.
	export SBCL_HOME="${EPREFIX}/usr/$(get_libdir)/sbcl"
	export HOME="${T}/home"
	mkdir -p "${HOME}" || die
}

# shellcheck disable=SC2329 # used by Portage phase functions
src_compile() {
	qlot_sandbox_env

	[[ -f "${S}/.bundle-libs/setup.lisp" ]] ||
		die "missing ${S}/.bundle-libs/setup.lisp (need the GitHub release tarball, not the git-tag archive)"

	# Loads .bundle-libs; does not fetch beta.quicklisp.org when the bundle exists.
	# Do not run scripts/install.sh (it ln -s's ${S} into /usr/local).
	bash "${S}/scripts/setup.sh" || die "scripts/setup.sh failed"
}

# shellcheck disable=SC2329
src_test() {
	qlot_sandbox_env
	local ver rc=0
	ver=$("${S}/bin/qlot" --version) || rc=$?
	# Upstream print-version then uiop:quit -1 (shell 255).
	[[ ${ver} == *${PV}* ]] ||
		die "unexpected qlot version: ${ver} (exit ${rc})"
	einfo "src_test: ${ver} (upstream --version exit ${rc})"
}

# shellcheck disable=SC2329
src_install() {
	local dest="/usr/share/qlot"
	dodir "${dest}"
	cp -a "${S}/." "${ED}${dest}/" || die

	fperms 0755 "${dest}/bin/qlot"
	local script
	for script in "${ED}${dest}/scripts/"*.sh; do
		[[ -f ${script} ]] || die "expected executable trampoline scripts under ${dest}/scripts"
		fperms 0755 "${script#"${ED}"}"
	done

	dosym -r "${dest}/bin/qlot" /usr/bin/qlot

	dodoc LICENSE.txt README.markdown
}
