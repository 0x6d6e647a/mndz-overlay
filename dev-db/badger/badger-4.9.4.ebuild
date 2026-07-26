# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

# Private jemalloc pin (matches Gentoo distfiles; not a runtime dependency).
JEMALLOC_PV="5.3.0"

DESCRIPTION="BadgerDB – embeddable key-value database (CLI)"
HOMEPAGE="https://github.com/dgraph-io/badger"
SRC_URI="
	https://github.com/dgraph-io/badger/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/badger-${PV}/badger-${PV}-vendor.tar.xz
	jemalloc? (
		https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_PV}/jemalloc-${JEMALLOC_PV}.tar.bz2
	)
"

LICENSE="Apache-2.0 jemalloc? ( BSD-2 )"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ~mips ppc64 ~riscv ~s390 ~x64-macos ~x64-solaris x86"
IUSE="bash-completion fish-completion jemalloc test zsh-completion"
RESTRICT="!test? ( test )"

BDEPEND=">=dev-lang/go-1.23.0:="

# Strip upstream debug/listener noise that is printed on stdout around cobra
# completion scripts (main.go starts a /debug listener and prints jemalloc status).
_badger_filter_completion() {
	sed \
		-e '/^Listening for \/debug HTTP requests at port:/d' \
		-e '/^Port busy\. Trying another one\.\.\./d' \
		-e '/^jemalloc enabled:/d' \
		-e '/^Using Go memory$/d' \
		-e '/^Num Allocated Bytes at program end:/d'
}

src_compile() {
	# Package path is ./badger (directory); do not use -o badger or the binary
	# is written as badger/badger and dobin fails on a directory.
	local out="${T}/badger"

	if use jemalloc; then
		local je="${WORKDIR}/jemalloc-prefix"
		local jemalloc_src="${WORKDIR}/jemalloc-${JEMALLOC_PV}"
		[[ -d ${jemalloc_src} ]] || die "jemalloc source not found at ${jemalloc_src}"

		pushd "${jemalloc_src}" >/dev/null || die
		econf \
			--prefix="${je}" \
			--libdir="${je}/lib" \
			--includedir="${je}/include" \
			--docdir="${je}/share/doc/jemalloc" \
			--disable-shared \
			--enable-static \
			--with-jemalloc-prefix=je_ \
			--with-malloc-conf=background_thread:true,metadata_thp:auto
		emake
		# Install only what CGO needs. Full `install` still targets system docdir
		# paths under some autotools layouts and trips the Portage sandbox.
		emake install_lib install_include
		popd >/dev/null || die

		# Prefer PIC archive for CGO/Go link; fall back to non-PIC static.
		local jelib
		if [[ -f ${je}/lib/libjemalloc_pic.a ]]; then
			jelib="${je}/lib/libjemalloc_pic.a"
		elif [[ -f ${je}/lib/libjemalloc.a ]]; then
			jelib="${je}/lib/libjemalloc.a"
		else
			die "private jemalloc static library missing under ${je}/lib"
		fi
		[[ -f ${je}/include/jemalloc/jemalloc.h ]] || die "private jemalloc headers missing"

		# ristretto hardcodes #cgo LDFLAGS to /usr/local/lib/libjemalloc.a
		local calloc
		calloc="$(find "${WORKDIR}/go-mod" -path '*/z/calloc_jemalloc.go' -print -quit)"
		[[ -n ${calloc} && -f ${calloc} ]] || die "ristretto calloc_jemalloc.go not found in go-mod cache"
		sed -i \
			-e "s|^\\(#cgo LDFLAGS:\\).*|\\1 ${jelib} -lm -lstdc++ -pthread -ldl|" \
			"${calloc}" || die

		export CGO_ENABLED=1
		export CGO_CFLAGS="${CGO_CFLAGS} -I${je}/include"
		ego build -tags=jemalloc -v -x -work -o "${out}" ./badger
	else
		export CGO_ENABLED=0
		ego build -v -x -work -o "${out}" ./badger
	fi
}

src_install() {
	einstalldocs
	dobin "${T}/badger"

	# PersistentPreRunE requires --dir even for completion generation.
	if use bash-completion; then
		"${T}/badger" --dir /var/empty completion bash 2>/dev/null \
			| _badger_filter_completion > badger.bash \
			|| die "failed to generate bash completion"
		newbashcomp badger.bash badger
	fi
	if use fish-completion; then
		"${T}/badger" --dir /var/empty completion fish 2>/dev/null \
			| _badger_filter_completion > badger.fish \
			|| die "failed to generate fish completion"
		newfishcomp badger.fish badger.fish
	fi
	if use zsh-completion; then
		"${T}/badger" --dir /var/empty completion zsh 2>/dev/null \
			| _badger_filter_completion > badger.zsh \
			|| die "failed to generate zsh completion"
		newzshcomp badger.zsh _badger
	fi
}

src_test() {
	ego test ./...
}
