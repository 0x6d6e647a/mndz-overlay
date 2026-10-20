# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_13 )
inherit python-single-r1

DESCRIPTION="CMake LSP Implementation"
HOMEPAGE="https://github.com/regen100/cmake-language-server"
SRC_URI="
	https://github.com/regen100/cmake-language-server/archive/refs/tags/v0.1.11.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/cmake-language-server-${PV}/cmake-language-server-${PV}-deps.tar.xz
"

S="${WORKDIR}/${P}"
LICENSE="MIT"
SLOT="0"
# Tilde form of every arch that ::gentoo dev-lang/python slot 3.12 keywords.
# python-3.12.14 and python-3.12.15, free-threaded slots excluded, 9999 excluded.
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+format test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	dev-lang/python:3.13
	dev-build/cmake
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	dev-lang/python:3.13
	dev-build/cmake
	dev-python/pdm
"

# pdm runs the venv interpreter as `python -EsS` on the host pdm tree.
# -E ignores PYTHONDONTWRITEBYTECODE, so that process tries to write
# bytecode beside the system modules. Predict the site-packages directory:
# the sandbox still denies the writes, and the merge does not fail.
pdm_predict_host_bytecode() {
	local script shebang py site found=0
	for script in /usr/lib/python-exec/*/pdm; do
		[[ -f ${script} ]] || continue
		found=1
		shebang=$(head -n 1 "${script}") || die
		py=${shebang#\#!}
		py=${py%%[[:space:]]*}
		site=$(
			"${py}" -c 'import pdm, pathlib; print(pathlib.Path(next(iter(pdm.__path__))).resolve().parent)'
		) || die
		addpredict "${site}"
	done
	[[ ${found} -eq 1 ]] || die "pdm python-exec script is missing"
}

# Point the implicit PyPI source at the unpacked dists/ directory.
# src_test runs before src_install, so both phases share this edit.
pdm_point_pypi_at_dists() {
	local pyproject="${S}/pyproject.toml"
	[[ -f ${pyproject} ]] || die "pyproject.toml is missing"
	if grep -q 'type = "find_links"' "${pyproject}"; then
		return 0
	fi
	cat >> "${pyproject}" <<-EOF || die
	[[tool.pdm.source]]
	name = "pypi"
	url = "file://${WORKDIR}/dists"
	type = "find_links"
	verify_ssl = false
	EOF
}

# The venv is created at /usr/lib/cmake-language-server inside the image and
# is not moved. Text files record the image path; rewrite those onto the
# merged path. Symlinks stay pointed at the system interpreter.
pdm_rewrite_venv_paths() {
	local venv=$1 dest=$2
	/usr/bin/python3.13 -c '
import pathlib, sys
root, old, new = sys.argv[1:]
old_b, new_b = old.encode(), new.encode()
for path in pathlib.Path(root).rglob("*"):
    if not path.is_file() or path.is_symlink():
        continue
    data = path.read_bytes()
    if b"\0" in data or old_b not in data:
        continue
    path.write_bytes(data.replace(old_b, new_b))
' "${venv}" "${venv}" "${dest}" || die
}

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

src_prepare() {
	default
	# pytest imports the source tree. pdm-backend writes this same line.
	printf '__version__ = "%s"\n' "${PV}" > cmake_language_server/version.py || die
	pdm_point_pypi_at_dists
}

src_test() {
	pdm_predict_host_bytecode
	local venv="${T}/venv" saved_path="${PATH}"
	/usr/bin/python3.13 -m venv "${venv}" || die
	export VIRTUAL_ENV="${venv}"
	export PATH="${venv}/bin:${PATH}"
	export PDM_CHECK_UPDATE=false
	# A bare /usr/bin/python3.13 makes pdm create ${S}/.venv and sync into it.
	# Point at the interpreter inside the virtualenv we just created.
	pdm use -f "${venv}/bin/python" || die
	PDM_BUILD_SCM_VERSION="${PV}" pdm sync -G dev || die
	"${venv}/bin/python" -m pytest tests \
		--deselect tests/test_api.py::test_parse_variables \
		--deselect tests/test_api.py::test_parse_modules \
		--deselect 'tests/test_server.py::test_completions_triggercharacter[find_package(-Boost]' \
		|| die
	export PATH="${saved_path}"
	unset VIRTUAL_ENV
}

src_install() {
	pdm_predict_host_bytecode
	local dest=/usr/lib/${PN}
	local venv="${ED}${dest}"
	/usr/bin/python3.13 -m venv "${venv}" || die
	export VIRTUAL_ENV="${venv}"
	export PDM_CHECK_UPDATE=false
	# A bare /usr/bin/python3.13 makes pdm create ${S}/.venv and sync into it.
	# That tree is not merged. Install a non-editable copy into this virtualenv
	# so the console script survives after the work directory is removed.
	pdm use -f "${venv}/bin/python" || die
	PDM_BUILD_SCM_VERSION="${PV}" pdm sync --prod --no-editable || die
	if use format; then
		"${VIRTUAL_ENV}/bin/pip" install \
			--disable-pip-version-check \
			--no-index \
			--find-links="${WORKDIR}/dists" \
			'cmakelang==0.6.13' 'six==1.16.0' || die
	fi
	pdm_rewrite_venv_paths "${venv}" "${dest}"
	dosym "../lib/${PN}/bin/${PN}" "/usr/bin/${PN}"
	if use format; then
		dosym "../lib/${PN}/bin/cmake-format" /usr/bin/cmake-format
	fi
}
