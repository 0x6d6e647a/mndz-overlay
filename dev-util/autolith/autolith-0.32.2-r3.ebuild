# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

# Template body owned by seed packaging; manager rewrite may touch KEYWORDS,
# SBCL floor atom, and deps SRC_URI PV only (see support-dev-util-autolith).

DESCRIPTION="Live, self-modifying Common Lisp AI agent"
HOMEPAGE="https://github.com/luciusmagn/autolith"
SRC_URI="
	https://github.com/luciusmagn/autolith/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/autolith-${PV}/autolith-${PV}-deps.tar.xz
"

LICENSE="ISC"
# Inventoried projects (token). Autolith ISC; fff MIT; fff-c unique crate SPDX
# (not one line per crate); .qlot software + colorlisp vendor as follows.
# ISC: autolith, cl-colorist, cl-exec-sandbox, clifff, clinedi, colorlisp,
#	mcparen, sbcl-workers, sexp-store
# COLL-Attribution: cl-jobpond, colordiff, idsmall, parenchek,
#	sbcl-generations, sexp-config
# MIT: bordeaux-threads, cffi, closer-mop, dexador, serapeum, 3bz, babel,
#	cl+ssl, cl-tga, deflate, fast-http, fast-io, global-vars, idna, iterate,
#	parse-declarations, pngload, split-sequence, static-vectors, swap-bytes,
#	trivial-features, trivial-file-size, trivial-gray-streams, uiop,
#	usocket, fff, .qlot/asdf.lisp, Quicklisp client, colorlisp grammars +
#	tree-sitter core (except clojure CC0), bordeaux-threads docs theme
# BSD: cl-base64, ironclad, opticl, chipz, chunga, cl-jpeg, cl-ppcre,
#	ieee-floats, local-time, monkeylib-binary-data, nibbles, opticl-core,
#	parse-number, retrospectiff, salza2, skippy, smart-buffer, string-case,
#	yason, zpb-exif, zpng, iterate/ext/fiveam
# BSD-2: cl-cookie, flexi-streams, proc-parse, quri, xsubseq
# public-domain: alexandria, cl-utilities, parse-float, trivial-garbage,
#	iterate/ext/alexandria
# ZLIB: documentation-utils, mmap, pathname-utils, trivial-indent,
#	trivial-mimes
# LLGPL-2.1: lisp-namespace, trivia, trivial-cltl2, type-i
# Unlicense: trivial-macroexpand-all
# WTFPL-2: introspect-environment
# icu: colorlisp vendor/tree-sitter/src/unicode
# CC0-1.0: colorlisp clojure grammar
# fff-c crates: unique SPDX (Apache-2.0, Apache-2.0-with-LLVM-exceptions,
#	Boost-1.0, MIT-0, MPL-2.0, Unicode-3.0, plus tokens already listed).
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Boost-1.0
	CC0-1.0 COLL-Attribution ISC LLGPL-2.1 MIT MIT-0 MPL-2.0
	Unicode-3.0 Unlicense WTFPL-2 ZLIB icu public-domain
"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~riscv ~sparc ~x64-macos ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

# Floor matches upstream sbcl.version at this tag; subslot rebuild on SBCL PV.
RDEPEND="
	>=dev-lisp/sbcl-2.6.6:=[source]
	dev-libs/openssl:=
	sys-apps/bubblewrap
	dev-vcs/git
"
BDEPEND="
	${RDEPEND}
	|| ( dev-lang/rust-bin dev-lang/rust )
	virtual/pkgconfig
"

# shellcheck disable=SC2329 # used by Portage phase functions
src_unpack() {
	default
	# Deps tarball layout: top-level .qlot/ and fff/
	cd "${WORKDIR}" || die
	unpack "autolith-${PV}-deps.tar.xz"
}

# shellcheck disable=SC2329
src_prepare() {
	default

	# Floor-check host SBCL against upstream pin (minimum), then capture
	# the actual lisp-implementation-version for identity stamping.
	local floor host_pv
	floor=$(tr -d '[:space:]' < sbcl.version) || die
	: "${SBCL_HOME:=/usr/$(get_libdir)/sbcl}"
	export SBCL_HOME
	host_pv=$(
		sbcl --noinform --no-userinit --no-sysinit --non-interactive \
			--eval '(write-string (lisp-implementation-version))' \
			--eval '(terpri)'
	) || die "could not probe host SBCL version"
	host_pv=$(echo "${host_pv}" | tr -d '[:space:]')

	ver_test "${host_pv}" -ge "${floor}" ||
		die "host SBCL ${host_pv} is older than Autolith floor ${floor} (need >=dev-lisp/sbcl-2.6.6:=[source]-${floor}[source])"

	# Stamp build-time identity into the tree (build ≡ run ≡ sources).
	printf '%s\n' "${host_pv}" > sbcl.version || die
	einfo "Stamped sbcl.version=${host_pv} (floor was ${floor})"

	# Disable network SBCL install paths in the runtime adapter.
	# Packaged installs must use system SBCL + synthetic source root only.
	cat > bin/autolith-runtime <<'EOF' || die
#!/usr/bin/env bash
# Gentoo packaging: network SBCL install is disabled.
# Use system SBCL from RDEPEND and AUTOLITH_SBCL / AUTOLITH_SBCL_SOURCE_ROOT.
set -euo pipefail

fail() {
	printf 'Autolith (Gentoo package): %s\n' "$1" >&2
	printf 'Install >=dev-lisp/sbcl-2.6.6:=[source] with USE=source; do not use bin/autolith-runtime --install.\n' >&2
	exit 1
}

adapter_path=$(readlink -f -- "${BASH_SOURCE[0]}")
source_root=$(CDPATH= cd -- "$(dirname -- "$adapter_path")/.." && pwd)
expected_version=$(tr -d '[:space:]' < "$source_root/sbcl.version")

install_requested=false
script_path=
script_arguments=()

while (($#)); do
	case "$1" in
		--install)
			install_requested=true
			shift
			;;
		--script)
			(($# >= 2)) || fail "--script needs a pathname."
			script_path=$2
			shift 2
			while (($#)); do
				script_arguments+=("$1")
				shift
			done
			;;
		*)
			fail "unknown argument $1."
			;;
	esac
done

[[ -n "$script_path" ]] || fail "no Lisp script was provided."
[[ -f "$script_path" ]] || fail "Lisp script $script_path does not exist."

if [[ "$install_requested" == true ]]; then
	fail "network SBCL download/install is disabled in the packaged Autolith."
fi

sbcl_command=${AUTOLITH_SBCL:-}
if [[ -z "$sbcl_command" ]]; then
	sbcl_command=$(command -v sbcl 2>/dev/null) || fail "SBCL not found; set AUTOLITH_SBCL or install >=dev-lisp/sbcl-2.6.6:=[source]."
fi
[[ -x "$sbcl_command" ]] || fail "AUTOLITH_SBCL does not name an executable."

actual=$("$sbcl_command" --noinform --no-userinit --no-sysinit --non-interactive \
	--eval '(write-string (lisp-implementation-version))' 2>/dev/null) ||
	fail "could not probe SBCL version."
actual=$(printf '%s' "$actual" | tr -d '[:space:]')
[[ "$actual" == "$expected_version" ]] ||
	fail "SBCL is $actual, packaged Autolith expects $expected_version."

exec "$sbcl_command" --script "$script_path" "${script_arguments[@]}"
EOF
	chmod +x bin/autolith-runtime || die

	# Do not install script/install as a user entrypoint (network installer).
	if [[ -f script/install ]]; then
		chmod a-x script/install || die
	fi
}

# shellcheck disable=SC2329
src_compile() {
	local deps_root="${WORKDIR}"
	local qlot_src="${deps_root}/.qlot"
	local fff_src="${deps_root}/fff"
	local host_pv
	host_pv=$(tr -d '[:space:]' < sbcl.version) || die

	[[ -d ${qlot_src} ]] || die "deps tarball missing .qlot/ at ${qlot_src}"
	[[ -d ${fff_src} ]] || die "deps tarball missing fff/ at ${fff_src}"

	# Materialize offline .qlot into the source tree.
	rm -rf .qlot || die
	cp -a "${qlot_src}" .qlot || die

	# --- fff (cargo offline) ---
	einfo "Building fff (offline cargo)…"
	pushd "${fff_src}" >/dev/null || die
	# Prefer release lib path used by upstream build-fff.lisp.
	local cargo_target="${CARGO_TARGET_DIR:-${T}/fff-target}"
	export CARGO_TARGET_DIR="${cargo_target}"
	cargo build --offline --locked --release -p fff-c || die "cargo build fff-c failed"
	local fff_so
	fff_so=$(find "${cargo_target}" -type f -name 'libfff_c.so' -print -quit) || die
	[[ -n ${fff_so} && -f ${fff_so} ]] || die "libfff_c.so not produced"
	mkdir -p "${T}/natives" || die
	cp -a "${fff_so}" "${T}/natives/libfff_c.so" || die
	popd >/dev/null || die

	# --- colorlisp tree-sitter native (from .qlot software tree) ---
	einfo "Building colorlisp native library…"
	local colorlisp_c colorlisp_root
	colorlisp_c=$(
		find .qlot -type f -path '*/native/colorlisp-tree-sitter.c' -print -quit
	) || die
	[[ -n ${colorlisp_c} && -f ${colorlisp_c} ]] ||
		die "colorlisp native/colorlisp-tree-sitter.c not found under .qlot"
	colorlisp_root=$(dirname "$(dirname "${colorlisp_c}")") || die
	(
		cd "${colorlisp_root}" || die
		# Mirror nix package.nix compile line (offline; sources are vendored in git).
		# shellcheck disable=SC2046
		$(tc-getCC) -shared -fPIC -O2 -std=gnu11 -fvisibility=hidden \
			-I vendor/tree-sitter/include \
			-I vendor/tree-sitter/src \
			$(find vendor/grammars -mindepth 1 -maxdepth 1 -type d -printf '-I %p ') \
			-o "${T}/natives/libcolorlisp-tree-sitter.so" \
			native/colorlisp-tree-sitter.c \
			vendor/tree-sitter/src/lib.c \
			$(find vendor/grammars -type f -name parser.c -print | sort) \
			$(find vendor/grammars -type f -name scanner.c -print | sort) \
			|| die "colorlisp native build failed"
	)

	# --- cl-exec-sandbox helper ---
	einfo "Building cl-exec-sandbox helper…"
	local sandbox_helper sandbox_root
	sandbox_helper=$(
		find .qlot -type f -path '*/scripts/build-helper' -print -quit
	) || die
	[[ -n ${sandbox_helper} && -f ${sandbox_helper} ]] ||
		die "cl-exec-sandbox scripts/build-helper not found under .qlot"
	sandbox_root=$(dirname "$(dirname "${sandbox_helper}")") || die
	bash "${sandbox_helper}" || die "sandbox helper build failed"
	cp -a "${sandbox_root}/build/cl-exec-sandbox-helper" \
		"${T}/natives/cl-exec-sandbox-helper" || die

	# --- Prune uninstalled tracked files before fabricating git ---
	# HEAD must match the installed share tracked set.
	rm -rf .github nix server tests || die
	rm -f flake.nix flake.lock || die
	rm -f bin/autolith-release || die
	rm -f script/install script/bootstrap script/bootstrap.lisp \
		script/qlot-install.lisp script/build-fff script/build-fff.lisp || die
	rm -f sbcl-source.sha256 AGENTS.md AUTOLITH.org || die
	rm -rf native/fff || die
	rmdir native 2>/dev/null || true
	# Keep remaining script/ (runtime-requirement, build-sandbox, check*,
	# image builders). Those files are loaded or hashed into cores.
	# Omit human-only docs; keep prompt templates when present. Do not rm -rf docs.
	if [[ -d docs ]]; then
		local doc
		for doc in docs/* docs/.[!.]*; do
			[[ -e ${doc} ]] || continue
			case ${doc#docs/} in
			system-prompt.org | request-context.org) ;;
			*) rm -rf "${doc}" || die ;;
			esac
		done
	fi

	# --- Fabricate git identity for recovery/active provenance ---
	einfo "Fabricating git provenance for image builds…"
	if [[ ! -d .git ]]; then
		git init --quiet --initial-branch=master . || die
		git config user.name "Autolith Gentoo build" || die
		git config user.email "portage@localhost" || die
		git config gc.auto 0 || die
		git add --all || die
		GIT_AUTHOR_DATE='2000-01-01T00:00:00Z' \
			GIT_COMMITTER_DATE='2000-01-01T00:00:00Z' \
			git commit --quiet --message "Autolith ${PV} Portage source" || die
	fi
	git gc --quiet --prune=now || die
	rm -f .git/hooks/*.sample || die
	rm -f .git/index || die
	git read-tree HEAD || die
	# gc pack-refs can leave .git/refs empty; Portage drops empty dirs and
	# Git then refuses the tree as a repository. Keep a loose master ref.
	mkdir -p .git/refs/heads || die
	git update-ref refs/heads/master HEAD || die

	# --- Synthetic SBCL source root (USE=source layout) ---
	local gentoo_src="/usr/$(get_libdir)/sbcl/src"
	[[ -d ${gentoo_src} ]] ||
		die "Gentoo SBCL sources missing at ${gentoo_src}; need USE=source on >=dev-lisp/sbcl-2.6.6:=[source]"
	mkdir -p "${T}/sbcl-source-root" || die
	printf '"%s"\n' "${host_pv}" > "${T}/sbcl-source-root/version.lisp-expr" || die
	ln -sfn "${gentoo_src}" "${T}/sbcl-source-root/src" || die

	# Export env for core builds and later install.
	# SBCL_HOME is required for nested sbcl children under a clean Portage env.
	: "${SBCL_HOME:=/usr/$(get_libdir)/sbcl}"
	export SBCL_HOME
	export AUTOLITH_SBCL="$(command -v sbcl)"
	export AUTOLITH_SBCL_SOURCE_ROOT="${T}/sbcl-source-root"
	export AUTOLITH_FFF_LIBRARY="${T}/natives/libfff_c.so"
	export COLORLISP_NATIVE_LIBRARY="${T}/natives/libcolorlisp-tree-sitter.so"
	export CL_EXEC_SANDBOX_HELPER="${T}/natives/cl-exec-sandbox-helper"
	export CL_EXEC_SANDBOX_BWRAP="$(command -v bwrap)"
	export HOME="${T}/home"
	export XDG_DATA_HOME="${T}/xdg-data"
	export XDG_CACHE_HOME="${T}/xdg-cache"
	export XDG_STATE_HOME="${T}/xdg-state"
	mkdir -p "${HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" "${XDG_STATE_HOME}" || die

	# C lean A: emerge-time recovery + active cores under T, installed privately.
	# Manifests are written beside each core as manifest.sexp — use separate dirs.
	local recovery_core="${T}/cores/recovery/autolith-recovery.core"
	local active_core="${T}/cores/active/autolith-active.core"
	mkdir -p "${T}/cores/recovery" "${T}/cores/active" || die
	export AUTOLITH_RECOVERY_CORE="${recovery_core}"
	export AUTOLITH_ACTIVE_CORE="${active_core}"

	# Use --script alone (implies --disable-debugger --quit). Do NOT also pass
	# --non-interactive: on SBCL 2.6.x that combination can skip script body
	# and exit 0 without building a core.
	einfo "Building recovery core…"
	sbcl --noinform --no-userinit --no-sysinit \
		--script "${S}/script/build-recovery.lisp" \
		"${recovery_core}" \
		|| die "recovery core build failed"
	[[ -f ${recovery_core} ]] || die "recovery core missing after build"
	[[ -f ${T}/cores/recovery/manifest.sexp ]] ||
		die "recovery manifest.sexp missing after build"

	einfo "Building active core…"
	sbcl --noinform --no-userinit --no-sysinit \
		--script "${S}/script/build-active.lisp" \
		"${active_core}" \
		|| die "active core build failed"
	[[ -f ${active_core} ]] || die "active core missing after build"
	[[ -f ${T}/cores/active/manifest.sexp ]] ||
		die "active manifest.sexp missing after build"
}

# shellcheck disable=SC2329
src_install() {
	local autolith_share="/usr/share/autolith"
	local autolith_libdir="/usr/$(get_libdir)/autolith"
	local sharedir="${ED}${autolith_share}"
	local host_pv
	host_pv=$(tr -d '[:space:]' < sbcl.version) || die

	dodir "${autolith_share}"

	# ColorLisp vendor C is compile-only; strip it and other agreed .qlot
	# leaves from ${S} before the keep-list copy (deps tarball still has C).
	[[ -d .qlot ]] || die "missing .qlot at ${S}/.qlot"
	rm -rf .qlot/tmp || die
	local qlot_path
	while IFS= read -r qlot_path; do
		[[ -n ${qlot_path} ]] || continue
		rm -rf "${qlot_path}" || die
	done < <(
		find .qlot \( \
			-type d \( \
				-path '*/colorlisp*/vendor/grammars' \
				-o -path '*/colorlisp*/vendor/tree-sitter' \
				-o -path '*/colorlisp*/vendor/common' \
				-o -path '*/cl-exec-sandbox*/build' \
				-o -path '*/bordeaux-threads*/docs' \
				-o -path '*/ironclad*/testing' \
				-o -name '.github' \
			\) \
			-o -type f -path '*/colorlisp*/native/colorlisp-tree-sitter.c' \
			\) -print
		if [[ -d .qlot/dists/cffi ]]; then
			find .qlot/dists/cffi -type d \( -name doc -o -name tests -o -name examples \) -print
		fi
	)

	# Explicit keep list (not cp -a of ${S}).
	cp -a src autolith.asd qlfile qlfile.lock sbcl.version \
		"${sharedir}/" || die
	[[ -f .gitignore ]] && { cp -a .gitignore "${sharedir}/" || die; }
	[[ -f LICENSE ]] && { cp -a LICENSE "${sharedir}/" || die; }
	[[ -f README.org ]] && { cp -a README.org "${sharedir}/" || die; }
	[[ -f sbcl-source-releases.sha256 ]] && {
		cp -a sbcl-source-releases.sha256 "${sharedir}/" || die
	}
	cp -a .qlot "${sharedir}/" || die
	cp -a .git "${sharedir}/" || die
	keepdir "${autolith_share}/.git/refs"
	keepdir "${autolith_share}/.git/refs/heads"
	cp -a recovery "${sharedir}/" || die
	mkdir -p "${sharedir}/bin" || die
	cp -a bin/autolith bin/autolith-active bin/autolith-runtime \
		bin/autolith-search-worker "${sharedir}/bin/" || die
	cp -a script "${sharedir}/" || die
	if [[ -f docs/system-prompt.org || -f docs/request-context.org ]]; then
		mkdir -p "${sharedir}/docs" || die
		[[ -f docs/system-prompt.org ]] && {
			cp -a docs/system-prompt.org "${sharedir}/docs/" || die
		}
		[[ -f docs/request-context.org ]] && {
			cp -a docs/request-context.org "${sharedir}/docs/" || die
		}
	fi

	# Architecture-specific natives
	insinto "${autolith_libdir}/lib"
	doins "${T}/natives/libfff_c.so"
	doins "${T}/natives/libcolorlisp-tree-sitter.so"
	exeinto "${autolith_libdir}/libexec"
	doexe "${T}/natives/cl-exec-sandbox-helper"

	# Cores + manifests (dirname/core → dirname/manifest.sexp)
	insinto "${autolith_libdir}/cores/recovery"
	doins "${T}/cores/recovery/autolith-recovery.core"
	doins "${T}/cores/recovery/manifest.sexp"
	insinto "${autolith_libdir}/cores/active"
	doins "${T}/cores/active/autolith-active.core"
	doins "${T}/cores/active/manifest.sexp"

	# Synthetic SBCL source root under the share dest.
	dodir "${autolith_share}/sbcl-source"
	printf '"%s"\n' "${host_pv}" \
		> "${ED}${autolith_share}/sbcl-source/version.lisp-expr" || die
	dosym -r "/usr/$(get_libdir)/sbcl/src" "${autolith_share}/sbcl-source/src"

	# /usr/bin/autolith wrapper (two dests)
	local wrapper="${T}/autolith-wrapper"
	# Expand EPREFIX at install time (wrapper runs with set -u; EPREFIX is not
	# defined in the user's shell). Runtime overrides still use \${VAR:-...}.
	cat > "${wrapper}" <<EOF || die
#!/usr/bin/env bash
# Gentoo mndz-overlay wrapper for Autolith ${PV}
set -euo pipefail

share="${EPREFIX}${autolith_share}"
lib="${EPREFIX}${autolith_libdir}"
export AUTOLITH_SBCL="\${AUTOLITH_SBCL:-${EPREFIX}/usr/bin/sbcl}"
export AUTOLITH_SBCL_SOURCE_ROOT="\${AUTOLITH_SBCL_SOURCE_ROOT:-\${share}/sbcl-source}"
export AUTOLITH_FFF_LIBRARY="\${AUTOLITH_FFF_LIBRARY:-\${lib}/lib/libfff_c.so}"
export COLORLISP_NATIVE_LIBRARY="\${COLORLISP_NATIVE_LIBRARY:-\${lib}/lib/libcolorlisp-tree-sitter.so}"
export CL_EXEC_SANDBOX_HELPER="\${CL_EXEC_SANDBOX_HELPER:-\${lib}/libexec/cl-exec-sandbox-helper}"
export CL_EXEC_SANDBOX_BWRAP="\${CL_EXEC_SANDBOX_BWRAP:-\$(command -v bwrap)}"
export AUTOLITH_RECOVERY_CORE="\${AUTOLITH_RECOVERY_CORE:-\${lib}/cores/recovery/autolith-recovery.core}"
export AUTOLITH_ACTIVE_CORE="\${AUTOLITH_ACTIVE_CORE:-\${lib}/cores/active/autolith-active.core}"
export AUTOLITH_INSTALLATION_KIND="\${AUTOLITH_INSTALLATION_KIND:-gentoo}"

# Allow provenance git reads from the share tree.
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0="\${share}"
export GIT_OPTIONAL_LOCKS=0

exec bash "\${share}/bin/autolith" "\$@"
EOF
	newbin "${wrapper}" autolith

	dodoc README.org LICENSE || true
}

# shellcheck disable=SC2329
src_test() {
	# Minimal offline verification: stamped version + wrapper --version path
	# is not available pre-install; probe recovery core boots and reports.
	local host_pv
	host_pv=$(tr -d '[:space:]' < sbcl.version) || die
	[[ -f ${T}/cores/recovery/autolith-recovery.core ]] || die "recovery core missing for tests"
	[[ -f ${T}/natives/libfff_c.so ]] || die "fff library missing for tests"

	# Load packaged asd via qlot setup and assert version string.
	export AUTOLITH_SBCL="$(command -v sbcl)"
	export AUTOLITH_SBCL_SOURCE_ROOT="${T}/sbcl-source-root"
	export AUTOLITH_FFF_LIBRARY="${T}/natives/libfff_c.so"
	export COLORLISP_NATIVE_LIBRARY="${T}/natives/libcolorlisp-tree-sitter.so"
	export CL_EXEC_SANDBOX_HELPER="${T}/natives/cl-exec-sandbox-helper"
	export CL_EXEC_SANDBOX_BWRAP="$(command -v bwrap)"
	export HOME="${T}/home"
	export XDG_DATA_HOME="${T}/xdg-data"

	: "${SBCL_HOME:=/usr/$(get_libdir)/sbcl}"
	export SBCL_HOME
	sbcl --noinform --no-userinit --no-sysinit --non-interactive \
		--eval "(load \"${S}/.qlot/setup.lisp\")" \
		--eval "(asdf:load-asd \"${S}/autolith.asd\")" \
		--eval "(ql:quickload :autolith :silent t)" \
		--eval "(let ((v (asdf:component-version (asdf:find-system :autolith)))) (unless (string= v \"${PV}\") (error \"version ~A != ${PV}\" v)))" \
		--quit \
		|| die "offline autolith load / version check failed"

	einfo "src_test: offline load of autolith ${PV} succeeded (SBCL ${host_pv})"
}
