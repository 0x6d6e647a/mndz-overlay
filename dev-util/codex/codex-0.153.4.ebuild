# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES=""

declare -A GIT_CRATES=(
	[crossterm]='https://github.com/openai-oss-forks/crossterm;45fecb9508105988f42fe6ff0441783ed3717f92;crossterm-%commit%'
	[nucleo-matcher]='https://github.com/helix-editor/nucleo;4253de9faabb4e5c6d81d946a5e35a90f87347ee;nucleo-%commit%/matcher'
	[nucleo]='https://github.com/helix-editor/nucleo;4253de9faabb4e5c6d81d946a5e35a90f87347ee;nucleo-%commit%'
	[runfiles]='https://github.com/dzbarsky/rules_rust;b56cbaa8465e74127f1ea216f813cd377295ad81;rules_rust-%commit%/rust/runfiles'
	[tokio-tungstenite]='https://github.com/openai-oss-forks/tokio-tungstenite;0e5b2d73aa18dd9f0a50ee9ff199d5aef7594186;tokio-tungstenite-%commit%'
	[tungstenite]='https://github.com/openai-oss-forks/tungstenite-rs;4fffad30fe373adbdcffab9545e9e9bf4f2fc19f;tungstenite-rs-%commit%'
)

RUST_MIN_VER="1.95.0"
RUSTY_V8_VER="150.4.0"

# Chromium host clang 23 + rust-toolchain (Linux_x64) from rusty_v8 ${RUSTY_V8_VER} DEPS.
CLANG_DIST="clang-llvmorg-23-init-10931-g20b6ec66-11.tar.xz"
RUST_TC_DIST="rust-toolchain-4c4205163abcbd08948b3efab796c543ba1ea687-4-llvmorg-23-init-10931-g20b6ec66.tar.xz"

inherit cargo check-reqs shell-completion toolchain-funcs

CHECKREQS_MEMORY="15G"
CHECKREQS_DISK_BUILD="20G"

DESCRIPTION="OpenAI Codex CLI (from-source rusty_v8)"
HOMEPAGE="https://github.com/openai/codex"
SRC_URI="
	https://github.com/openai/${PN}/archive/refs/tags/rust-v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/codex-${PV}/${PN}-${PV}-crates.tar.xz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/rusty-v8-${RUSTY_V8_VER}/rusty-v8-${RUSTY_V8_VER}-with-submodules.tar.xz
	https://commondatastorage.googleapis.com/chromium-browser-clang/Linux_x64/${CLANG_DIST}
	https://commondatastorage.googleapis.com/chromium-browser-clang/Linux_x64/${RUST_TC_DIST}
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/${PN}-rust-v${PV}/codex-rs"

LICENSE="Apache-2.0"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD Boost-1.0
	CC0-1.0 CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="bash-completion fish-completion test zsh-completion"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-libs/openssl:=
	sys-apps/bubblewrap
"
BDEPEND="
	dev-build/gn
	dev-build/ninja
	dev-lang/python
	dev-libs/protobuf
	llvm-core/clang:22
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="
	usr/bin/codex
	usr/bin/codex-code-mode-host
"

pkg_pretend() {
	check-reqs_pkg_pretend
}

pkg_setup() {
	check-reqs_pkg_setup
	rust_pkg_setup
}

src_unpack() {
	cargo_src_unpack

	mkdir -p "${WORKDIR}/rusty_v8" || die
	tar -C "${WORKDIR}/rusty_v8" --strip-components=1 \
		-xf "${DISTDIR}/rusty-v8-${RUSTY_V8_VER}-with-submodules.tar.xz" || die

	mkdir -p "${WORKDIR}/chromium-clang" || die
	tar -C "${WORKDIR}/chromium-clang" \
		-xf "${DISTDIR}/${CLANG_DIST}" || die

	# Archive root is VERSION + bin/ + lib/ (Chromium layout). Do not
	# --strip-components=1: that drops VERSION (gn rust.gni reads it) and
	# flattens bin/lib so rustc cannot find librustc_driver.
	mkdir -p "${WORKDIR}/rusty_v8/third_party/rust-toolchain" || die
	tar -C "${WORKDIR}/rusty_v8/third_party/rust-toolchain" \
		-xf "${DISTDIR}/${RUST_TC_DIST}" || die
	[[ -f ${WORKDIR}/rusty_v8/third_party/rust-toolchain/VERSION ]] ||
		die "Chromium rust-toolchain VERSION missing after unpack"
	[[ -x ${WORKDIR}/rusty_v8/third_party/rust-toolchain/bin/rustc ]] ||
		die "Chromium rust-toolchain bin/rustc missing after unpack"
	# rusty_v8 tools/rust_toolchain.py skips GCS if this sentinel equals the
	# exact object URL (no trailing newline).
	printf '%s' \
		"https://storage.googleapis.com/chromium-browser-clang/Linux_x64/${RUST_TC_DIST}" \
		>"${WORKDIR}/rusty_v8/third_party/rust-toolchain/.rusty_v8_version" || die
}

src_prepare() {
	default

	local marker='protoc_bin_vendored::protoc_bin_path'
	local build_rs="${S}/code-mode-protocol/build.rs"
	grep -q "${marker}" "${build_rs}" ||
		die "vendored protoc marker missing from ${build_rs}; update src_prepare"
	# Point tonic at system protoc ($PROTOC or /usr/bin/protoc). Keep the
	# protoc-bin-vendored crates in the lock/tarball so --offline --locked resolves.
	# '#' delimiter: the replacement contains '|_|', which breaks s||| .
	# Match the trailing '?' so a String is not used as Result.
	sed -i \
		-e "s#${marker}()?#std::env::var(\"PROTOC\").unwrap_or_else(|_| \"/usr/bin/protoc\".into())#" \
		"${build_rs}" || die

	# Windows-only microsoft/mxc is omitted from GIT_CRATES, but Cargo still
	# resolves the workspace git pin for appcontainer_common --offline.
	mkdir -p "${WORKDIR}/appcontainer_common_stub/src" || die
	cat > "${WORKDIR}/appcontainer_common_stub/Cargo.toml" <<-EOF || die
		[package]
		name = "appcontainer_common"
		version = "0.8.0"
		edition = "2021"
	EOF
	: > "${WORKDIR}/appcontainer_common_stub/src/lib.rs" || die

	# crates.io v8 is not a from-source tree; path-patch onto the rusty_v8 snapshot.
	# cargo.eclass writes [patch] into CARGO_HOME/config.toml, but Cargo 1.96
	# ignores that and still fetches [patch.crates-io] git= remotes --offline.
	# Rewrite those git pins (and workspace git deps) to unpacked GIT_CRATES paths.
	python3 - "${WORKDIR}" "${S}/Cargo.toml" <<'PY' || die "rewrite Cargo.toml git crates to paths"
import sys
from pathlib import Path

workdir, toml_path = sys.argv[1], Path(sys.argv[2])
text = toml_path.read_text()
subs = [
    (
        'crossterm = { git = "https://github.com/openai-oss-forks/crossterm", rev = "45fecb9508105988f42fe6ff0441783ed3717f92" }',
        f'crossterm = {{ path = "{workdir}/crossterm-45fecb9508105988f42fe6ff0441783ed3717f92" }}',
    ),
    (
        'tokio-tungstenite = { git = "https://github.com/openai-oss-forks/tokio-tungstenite", rev = "0e5b2d73aa18dd9f0a50ee9ff199d5aef7594186" }',
        f'tokio-tungstenite = {{ path = "{workdir}/tokio-tungstenite-0e5b2d73aa18dd9f0a50ee9ff199d5aef7594186" }}',
    ),
    (
        'tungstenite = { git = "https://github.com/openai-oss-forks/tungstenite-rs", rev = "4fffad30fe373adbdcffab9545e9e9bf4f2fc19f" }',
        f'tungstenite = {{ path = "{workdir}/tungstenite-rs-4fffad30fe373adbdcffab9545e9e9bf4f2fc19f" }}',
    ),
    (
        'nucleo = { git = "https://github.com/helix-editor/nucleo.git", rev = "4253de9faabb4e5c6d81d946a5e35a90f87347ee" }',
        f'nucleo = {{ path = "{workdir}/nucleo-4253de9faabb4e5c6d81d946a5e35a90f87347ee" }}',
    ),
    (
        'runfiles = { git = "https://github.com/dzbarsky/rules_rust", rev = "b56cbaa8465e74127f1ea216f813cd377295ad81" }',
        f'runfiles = {{ path = "{workdir}/rules_rust-b56cbaa8465e74127f1ea216f813cd377295ad81/rust/runfiles" }}',
    ),
    (
        'appcontainer_common = { git = "https://github.com/microsoft/mxc", rev = "6cd3d58f05d3447e67109cfb75e042803b843ca4" }',
        f'appcontainer_common = {{ path = "{workdir}/appcontainer_common_stub" }}',
    ),
]
for old, new in subs:
    if old not in text:
        sys.exit(f"expected git crate snippet missing from Cargo.toml: {old}")
    text = text.replace(old, new)
needle = "[patch.crates-io]\n"
if needle not in text:
    sys.exit("Cargo.toml missing [patch.crates-io]")
text = text.replace(
    needle,
    needle + f'v8 = {{ path = "{workdir}/rusty_v8" }}\n',
    1,
)
toml_path.write_text(text)
PY
	local git_toml
	for git_toml in \
		"${WORKDIR}/crossterm-45fecb9508105988f42fe6ff0441783ed3717f92/Cargo.toml" \
		"${WORKDIR}/tokio-tungstenite-0e5b2d73aa18dd9f0a50ee9ff199d5aef7594186/Cargo.toml" \
		"${WORKDIR}/tungstenite-rs-4fffad30fe373adbdcffab9545e9e9bf4f2fc19f/Cargo.toml" \
		"${WORKDIR}/nucleo-4253de9faabb4e5c6d81d946a5e35a90f87347ee/Cargo.toml" \
		"${WORKDIR}/nucleo-4253de9faabb4e5c6d81d946a5e35a90f87347ee/matcher/Cargo.toml" \
		"${WORKDIR}/rules_rust-b56cbaa8465e74127f1ea216f813cd377295ad81/rust/runfiles/Cargo.toml" \
		"${WORKDIR}/rusty_v8/Cargo.toml"
	do
		[[ -f ${git_toml} ]] || die "unpacked git crate missing ${git_toml}"
	done
}

src_compile() {
	export V8_FROM_SOURCE=1
	# rusty_v8 gn uses this tree; do not export it as CC/CXX — cc-rs (ring)
	# would then compile with Chromium clang, which rejects Portage CFLAGS
	# such as -mabm.
	export CLANG_BASE_PATH="${WORKDIR}/chromium-clang"
	# Chromium clang has no 64-bit libclang.so; Gentoo clang:22 lib64 does.
	export LIBCLANG_PATH="/usr/lib/llvm/22/$(get_libdir)"
	export RUST_MIN_STACK=16777216

	cargo_src_compile --bin codex --bin codex-code-mode-host
}

src_test() {
	export V8_FROM_SOURCE=1
	export RUST_MIN_STACK=16777216
	# Skip network, sandbox, and known-failing crates under Portage FEATURES=test.
	# Remaining workspace members run via cargo.eclass.
	local CARGO_SKIP_TESTS=(
		# network
		codex-login
		# sandbox / bubblewrap host assumptions
		codex-linux-sandbox
	)
	export CARGO_SKIP_TESTS
	cargo_src_test
}

src_install() {
	dobin "$(cargo_target_dir)/codex"
	dobin "$(cargo_target_dir)/codex-code-mode-host"

	local cdir
	cdir="$(cargo_target_dir)"
	if use bash-completion; then
		"${cdir}/codex" completion bash > codex.bash || die
		newbashcomp codex.bash codex
	fi
	if use zsh-completion; then
		"${cdir}/codex" completion zsh > codex.zsh || die
		newzshcomp codex.zsh _codex
	fi
	if use fish-completion; then
		"${cdir}/codex" completion fish > codex.fish || die
		newfishcomp codex.fish codex.fish
	fi
}
