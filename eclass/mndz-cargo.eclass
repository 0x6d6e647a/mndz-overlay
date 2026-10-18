# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: mndz-cargo.eclass
# @MAINTAINER:
# Anthony Mendez <738092+0x6d6e647a@users.noreply.github.com>
# @SUPPORTED_EAPIS: 8
# @BLURB: rewrite one-line [patch.*] git pins from GIT_CRATES
# @DESCRIPTION:
# mndz-cargo_rewrite_patch_git_pins rewrites one-line [patch.*] git pins
# onto the unpacked GIT_CRATES checkouts. Ebuilds call it from src_prepare
# after default. This eclass does not export a phase.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_MNDZ_CARGO_ECLASS} ]]; then
_MNDZ_CARGO_ECLASS=1

# @FUNCTION: mndz-cargo_rewrite_patch_git_pins
# @DESCRIPTION:
# Rewrite each one-line [patch.*] git pin from GIT_CRATES onto its unpacked checkout.
mndz-cargo_rewrite_patch_git_pins() {
	# cargo.eclass writes [patch] into CARGO_HOME/config.toml. On Cargo 1.97
	# that table does not satisfy a git dependency listed under [patch.*].
	# Rewrite each one-line pin from GIT_CRATES onto its unpacked checkout.
	local -a pin_args=()
	local name spec commit dir
	for name in "${!GIT_CRATES[@]}"; do
		spec="${GIT_CRATES[${name}]}"
		IFS=';' read -r _ commit dir _ <<< "${spec}"
		[[ -n ${commit} && -n ${dir} ]] ||
			die "GIT_CRATES ${name} has no commit and directory"
		dir=${dir//%commit%/${commit}}
		pin_args+=("${name}" "${commit}" "${WORKDIR}/${dir}")
	done

	python3 - "${S}/Cargo.toml" "${pin_args[@]}" <<'PY' || die "rewrite [patch.*] git pins"
import re
import sys
from pathlib import Path

toml_path = Path(sys.argv[1])
if not toml_path.is_file():
    sys.exit(f"unpacked Cargo.toml missing: {toml_path}")

pin_args = sys.argv[2:]
if len(pin_args) % 3 != 0:
    sys.exit("git pin arguments are not name, commit, path triples")

pins = {}
for index in range(0, len(pin_args), 3):
    pin_name, pin_commit, pin_path = pin_args[index : index + 3]
    pins[(pin_name, pin_commit)] = pin_path

try:
    text = toml_path.read_bytes().decode("utf-8")
except UnicodeError:
    sys.exit(f"cannot parse patch git pin: {toml_path} is not utf-8")

lines = text.splitlines(keepends=True)

GIT_KEY = re.compile(r"(^|[{, \t])git[ \t]*=")
ASSIGN_START = re.compile(
    r"^(?P<indent>[ \t]*)(?P<name>[A-Za-z0-9_-]+)[ \t]*=[ \t]*(?P<rest>.*)$"
)
KEY_VALUE = re.compile(
    r"^(?P<key>[A-Za-z0-9_-]+)[ \t]*=[ \t]*(?P<value>.*)$"
)
GIT_SOURCE_KEYS = {"git", "rev", "branch", "tag"}


def die(message):
    sys.exit(message)


def code_portion(body):
    out = []
    in_str = False
    escape = False
    quote = ""
    for ch in body:
        if in_str:
            out.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                in_str = False
            continue
        if ch in "\"'":
            in_str = True
            quote = ch
            out.append(ch)
            continue
        if ch == "#":
            break
        out.append(ch)
    return "".join(out).rstrip()


def split_ending(line):
    if line.endswith("\r\n"):
        return line[:-2], "\r\n"
    if line.endswith("\n"):
        return line[:-1], "\n"
    if line.endswith("\r"):
        return line[:-1], "\r"
    return line, ""


def brace_delta(fragment):
    depth = 0
    in_str = False
    escape = False
    quote = ""
    for ch in fragment:
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                in_str = False
            continue
        if ch in "\"'":
            in_str = True
            quote = ch
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
    return depth


def split_inline(body):
    parts = []
    buf = []
    depth_brace = 0
    depth_bracket = 0
    in_str = False
    escape = False
    quote = ""
    for ch in body:
        if in_str:
            buf.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                in_str = False
            continue
        if ch in "\"'":
            in_str = True
            quote = ch
            buf.append(ch)
            continue
        if ch == "{":
            depth_brace += 1
        elif ch == "}":
            if depth_brace == 0:
                return None
            depth_brace -= 1
        elif ch == "[":
            depth_bracket += 1
        elif ch == "]":
            if depth_bracket == 0:
                return None
            depth_bracket -= 1
        if ch == "," and depth_brace == 0 and depth_bracket == 0:
            parts.append("".join(buf).strip())
            buf = []
            continue
        buf.append(ch)
    if in_str or depth_brace or depth_bracket:
        return None
    tail = "".join(buf).strip()
    if tail:
        parts.append(tail)
    return parts


def unquote(value):
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return None


def toml_escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def rewrite_body(name, body):
    parts = split_inline(body)
    if parts is None:
        die(f"cannot parse patch git pin {name}")
    items = []
    rev = None
    saw_git = False
    for part in parts:
        if part == "":
            continue
        match = KEY_VALUE.match(part)
        if not match:
            die(f"cannot parse patch git pin {name}")
        key = match.group("key")
        value = match.group("value").strip()
        if key == "git":
            saw_git = True
        if key == "rev":
            rev = unquote(value)
            if rev is None:
                die(f"cannot parse patch git pin {name}")
        items.append((key, value, key in GIT_SOURCE_KEYS))
    if not saw_git or not rev:
        die(f"cannot parse patch git pin {name}")
    path = pins.get((name, rev))
    if path is None:
        die(f"GIT_CRATES has no {name} rev {rev}")
    checkout = Path(path) / "Cargo.toml"
    if not checkout.is_file():
        die(f"unpacked Cargo.toml missing for {name}: {checkout}")
    rendered = []
    placed = False
    escaped = toml_escape(path)
    for key, value, is_source in items:
        if is_source:
            if not placed:
                rendered.append(f'path = "{escaped}"')
                placed = True
            continue
        rendered.append(f"{key} = {value}")
    return "{ " + ", ".join(rendered) + " }"


out = []
in_patch = False
index = 0
while index < len(lines):
    line = lines[index]
    body, newline = split_ending(line)
    code = code_portion(body)
    stripped = code.lstrip()
    if stripped.startswith("["):
        in_patch = stripped.startswith("[patch.")
        out.append(line)
        index += 1
        continue
    if not in_patch or stripped == "" or stripped.startswith("#"):
        out.append(line)
        index += 1
        continue
    if GIT_KEY.search(code) is None and "{" not in code:
        out.append(line)
        index += 1
        continue
    match = ASSIGN_START.match(code)
    if not match:
        die("cannot parse patch git pin")
    indent = match.group("indent")
    name = match.group("name")
    rest = match.group("rest").strip()
    depth = brace_delta(code)
    if depth < 0 or not rest.startswith("{"):
        die(f"cannot parse patch git pin {name}")
    block_lines = [line]
    block_codes = [code]
    cursor = index
    while depth > 0:
        cursor += 1
        if cursor >= len(lines):
            die(f"cannot parse patch git pin {name}")
        next_line = lines[cursor]
        next_body, _next_newline = split_ending(next_line)
        next_code = code_portion(next_body)
        block_lines.append(next_line)
        block_codes.append(next_code)
        depth += brace_delta(next_code)
        if depth < 0:
            die(f"cannot parse patch git pin {name}")
    if cursor != index:
        if GIT_KEY.search("\n".join(block_codes)):
            die(f"cannot parse patch git pin {name}")
        out.extend(block_lines)
        index = cursor + 1
        continue
    if GIT_KEY.search(code) is None:
        out.append(line)
        index += 1
        continue
    if not rest.endswith("}"):
        die(f"cannot parse patch git pin {name}")
    rewritten = rewrite_body(name, rest[1:-1])
    out.append(f"{indent}{name} = {rewritten}{newline}")
    index += 1

toml_path.write_bytes("".join(out).encode("utf-8"))
PY
}

fi
