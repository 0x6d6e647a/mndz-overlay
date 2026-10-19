# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_13 )
inherit python-single-r1

DESCRIPTION="MCP server for delegating tasks to Codex CLI subagents"
HOMEPAGE="https://github.com/kky42/codex-as-mcp"
# Archive tag is the raw git tag. This seed tag has no v prefix.
SRC_URI="
	https://github.com/kky42/codex-as-mcp/archive/refs/tags/2026.2.2.1.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/codex-as-mcp-${PV}/codex-as-mcp-${PV}-deps.tar.xz
"

S="${WORKDIR}/${P}"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="external-codex test"
RESTRICT="!test? ( test )"

RDEPEND="
	${PYTHON_DEPS}
	dev-lang/python:3.13
	!external-codex? ( dev-util/codex )
"
DEPEND="${RDEPEND}"
# PEP 517 backends are sdists in the deps tarball. The toolchain stays here.
BDEPEND="
	${PYTHON_DEPS}
	dev-python/uv
	|| ( dev-lang/rust-bin dev-lang/rust )
	dev-libs/openssl
	dev-libs/libffi
	test? ( dev-python/pytest )
"

src_unpack() {
	default
	# GitHub archive root is ${PN}-<raw-tag>. Move it onto ${P} when the tag
	# spelling differs from PV (a v-prefixed tag).
	if [[ ! -d ${P} ]]; then
		local d
		for d in "${WORKDIR}/${PN}-"*; do
			[[ -d ${d} ]] || continue
			mv "${d}" "${WORKDIR}/${P}" || die
			break
		done
	fi
}

# uv sync --frozen selects the lock's wheels and checks the original sdist
# hashes. cargo vendor rewrites the Rust sdists, so those hashes do not match.
# Export the pins without hashes and build every distribution from sdists/.
uv_install_from_sdists() {
	local venv=$1
	shift
	export UV_OFFLINE=1
	export UV_PYTHON_DOWNLOADS=never
	export CARGO_NET_OFFLINE=true
	export UV_CACHE_DIR="${T}/uv-cache"
	export CARGO_HOME="${T}/cargo"

	uv venv --python /usr/bin/python3.13 "${venv}" || die
	uv export \
		--directory "${S}" \
		--frozen \
		"$@" \
		--no-hashes \
		--no-emit-project \
		--offline \
		--python /usr/bin/python3.13 \
		-o "${T}/requirements.txt" || die
	# Portage exports PYTHON to the system interpreter. pydantic-core's
	# build.rs runs generate_self_schema.py with that variable when it is
	# set. The script imports typing_extensions, which the isolated build
	# env has and the system interpreter does not. maturin already sets
	# PYO3_PYTHON to the isolated interpreter.
	env -u PYTHON \
		uv pip install \
		--python "${venv}/bin/python" \
		--offline \
		--no-index \
		--find-links "${WORKDIR}/sdists" \
		--no-binary :all: \
		-r "${T}/requirements.txt" || die
}

src_install() {
	local external=no venv site
	use external-codex && external=yes
	venv="${ED}/usr/lib/${PN}"
	uv_install_from_sdists "${venv}" --no-dev
	site="$("${venv}/bin/python" -c 'import sysconfig; print(sysconfig.get_path("purelib"))')" || die
	cp -a "${S}/src/codex_as_mcp" "${site}/" || die

	dodir /usr/bin
	cat > "${ED}/usr/bin/${PN}" <<-EOF || die
	#!/bin/sh
	if [ -n "\${CODEX_PATH+x}" ]; then
		base=\$(basename "\$CODEX_PATH")
		if [ "\$base" != codex ]; then
			echo "CODEX_PATH must name a codex executable" >&2
			exit 1
		fi
		PATH=\$(dirname "\$CODEX_PATH"):\$PATH
	elif [ "${external}" = no ]; then
		PATH=/usr/bin:\$PATH
	fi
	export PATH
	exec /usr/lib/${PN}/bin/python -m codex_as_mcp "\$@"
	EOF
	fperms 0755 "/usr/bin/${PN}" || die
}

src_test() {
	[[ -f tests/test_server.py ]] || return 0
	local venv site
	venv="${T}/venv"
	uv_install_from_sdists "${venv}" --all-groups
	site="$("${venv}/bin/python" -c 'import sysconfig; print(sysconfig.get_path("purelib"))')" || die
	cp -a "${S}/src/codex_as_mcp" "${site}/" || die
	"${venv}/bin/python" -m pytest tests/test_server.py || die
}

pkg_postinst() {
	ewarn "${PN} launches Codex with approvals and the sandbox bypassed."
}
