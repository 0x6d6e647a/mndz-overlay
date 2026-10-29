# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: mndz-cargo.eclass
# @MAINTAINER:
# Anthony Mendez <738092+0x6d6e647a@users.noreply.github.com>
# @SUPPORTED_EAPIS: 8
# @BLURB: rewrite Storytold git pins onto fetched checkouts
# @DESCRIPTION:
# mndz-cargo_rewrite_patch_git_pins rewrites one-line [patch.*] git pins
# onto unpacked checkouts and registers a workspace git dependency that
# Cargo.lock records when that package is already fetched. Ebuilds call it
# from src_prepare after default. This eclass does not export a phase.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_MNDZ_CARGO_ECLASS} ]]; then
_MNDZ_CARGO_ECLASS=1

# @FUNCTION: mndz-cargo_rewrite_patch_git_pins
# @DESCRIPTION:
# Rewrite each one-line [patch.*] git pin onto its unpacked checkout. A pin
# with no GIT_CRATES key is taken from the one archive root already fetched
# for that commit whose [package].name matches. A workspace git line stays
# git. When Cargo.lock records that package and exactly one fetched archive
# contains it, the package is added to GIT_CRATES and cargo_gen_config runs
# again.
mndz-cargo_rewrite_patch_git_pins() {
	# cargo.eclass writes [patch] into CARGO_HOME/config.toml. On Cargo 1.97
	# that table does not satisfy a git dependency listed under [patch.*].
	# Rewrite each one-line pin onto its unpacked checkout. A missing
	# GIT_CRATES key uses [package].name inside the archive for that commit.
	local -a pin_args=()
	local name spec url commit dir
	for name in "${!GIT_CRATES[@]}"; do
		spec="${GIT_CRATES[${name}]}"
		IFS=';' read -r url commit dir _ <<< "${spec}"
		[[ -n ${commit} && -n ${dir} ]] ||
			die "GIT_CRATES ${name} has no commit and directory"
		pin_args+=("${name}" "${url}" "${commit}" "${dir}")
	done

	local added
	added=$(
		python3 - "${S}" "${WORKDIR}" "${pin_args[@]}" <<'PY'
import re
import sys
from pathlib import Path

source_root = Path(sys.argv[1])
workdir = Path(sys.argv[2])
toml_path = source_root / "Cargo.toml"
if not toml_path.is_file():
    sys.exit(f"unpacked Cargo.toml missing: {toml_path}")

pin_args = sys.argv[3:]
if len(pin_args) % 4 != 0:
    sys.exit("git pin arguments are not name, url, commit, directory tuples")

entries = []
pins = {}
known_names = set()
for index in range(0, len(pin_args), 4):
    pin_name, pin_url, pin_commit, pin_dir = pin_args[index : index + 4]
    entries.append(
        {
            "name": pin_name,
            "url": pin_url,
            "commit": pin_commit,
            "dir": pin_dir,
        }
    )
    expanded = pin_dir.replace("%commit%", pin_commit)
    pins[(pin_name, pin_commit)] = str(workdir / expanded)
    known_names.add(pin_name)

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
    path = resolve_pin_path(name, rev)
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


_root_index = {}


def index_root(root):
    key = str(root)
    cached = _root_index.get(key)
    if cached is not None:
        return cached
    found = {}
    if root.is_dir():
        for cargo in root.rglob("Cargo.toml"):
            name = package_name(cargo)
            if name:
                found.setdefault(name, []).append(cargo.parent)
    _root_index[key] = found
    return found


def package_name(path):
    try:
        text = path.read_bytes().decode("utf-8")
    except (OSError, UnicodeError):
        return None
    in_package = False
    for line in text.splitlines():
        body, _newline = split_ending(line)
        code = code_portion(body)
        stripped = code.strip()
        if stripped.startswith("["):
            in_package = stripped == "[package]"
            continue
        if not in_package or stripped == "":
            continue
        match = KEY_VALUE.match(stripped)
        if not match or match.group("key") != "name":
            continue
        return unquote(match.group("value").strip())
    return None


def roots_for(commit):
    found = {}
    for entry in entries:
        if entry["commit"] != commit:
            continue
        expanded = entry["dir"].replace("%commit%", commit)
        root = expanded.split("/", 1)[0]
        if root in ("", "."):
            die(f"GIT_CRATES {entry['name']} has no archive root")
        found.setdefault(root, set()).add(entry["url"])
    return found


def find_matches(commit, package):
    matches = []
    for root, urls in roots_for(commit).items():
        for pkg_dir in index_root(workdir / root).get(package, []):
            matches.append((root, pkg_dir, frozenset(urls)))
    return matches


def resolve_pin_path(name, rev):
    keyed = pins.get((name, rev))
    if keyed is not None:
        checkout = Path(keyed) / "Cargo.toml"
        if not checkout.is_file():
            die(f"unpacked Cargo.toml missing for {name}: {checkout}")
        return keyed
    matches = find_matches(rev, name)
    if len(matches) == 0:
        die(f"GIT_CRATES has no {name} rev {rev}")
    if len(matches) != 1:
        die(f"multiple checkouts for {name} rev {rev}")
    return str(matches[0][1])


def git_rev_of(name, body):
    parts = split_inline(body)
    if parts is None:
        die(f"cannot parse git dependency {name}")
    rev = None
    saw_git = False
    for part in parts:
        if part == "":
            continue
        match = KEY_VALUE.match(part)
        if not match:
            die(f"cannot parse git dependency {name}")
        key = match.group("key")
        value = match.group("value").strip()
        if key == "git":
            saw_git = True
        elif key == "rev":
            rev = unquote(value)
            if rev is None:
                die(f"cannot parse git dependency {name}")
    if not saw_git:
        return None
    return rev


def workspace_git_deps(root):
    found = {}
    for cargo in sorted(root.rglob("Cargo.toml")):
        try:
            text = cargo.read_bytes().decode("utf-8")
        except (OSError, UnicodeError):
            die(f"cannot parse git dependency: {cargo} is not utf-8")
        in_patch = False
        lines_here = text.splitlines()
        index = 0
        while index < len(lines_here):
            line = lines_here[index]
            body, _newline = split_ending(line)
            code = code_portion(body)
            stripped = code.lstrip()
            if stripped.startswith("["):
                in_patch = stripped.startswith("[patch.")
                index += 1
                continue
            if in_patch or stripped == "" or GIT_KEY.search(code) is None:
                index += 1
                continue
            match = ASSIGN_START.match(code)
            if not match:
                index += 1
                continue
            name = match.group("name")
            rest = match.group("rest").strip()
            if not rest.startswith("{"):
                index += 1
                continue
            depth = brace_delta(code)
            if depth < 0:
                die(f"cannot parse git dependency {name}")
            cursor = index
            while depth > 0:
                cursor += 1
                if cursor >= len(lines_here):
                    die(f"cannot parse git dependency {name}")
                next_body, _next_newline = split_ending(lines_here[cursor])
                depth += brace_delta(code_portion(next_body))
                if depth < 0:
                    die(f"cannot parse git dependency {name}")
            if cursor != index:
                index = cursor + 1
                continue
            if not rest.endswith("}"):
                die(f"cannot parse git dependency {name}")
            rev = git_rev_of(name, rest[1:-1])
            if rev:
                found.setdefault(name, set()).add(rev)
            index += 1
    return found


def lock_records(lock_text, name, commit):
    current_name = None
    current_source = None

    def flush():
        if current_name != name or not current_source:
            return False
        if not current_source.startswith("git+"):
            return False
        if "#" in current_source and current_source.rsplit("#", 1)[1] == commit:
            return True
        return (
            re.search(
                r"(?:^|[?&])rev=" + re.escape(commit) + r"(?:$|&|#)",
                current_source,
            )
            is not None
        )

    for line in lock_text.splitlines():
        if line.startswith("[[package]]"):
            if flush():
                return True
            current_name = None
            current_source = None
            continue
        stripped = line.strip()
        if stripped.startswith("name = "):
            current_name = unquote(stripped[len("name = ") :].strip())
        elif stripped.startswith("source = "):
            current_source = unquote(stripped[len("source = ") :].strip())
    return flush()


def percent_commit_dir(pkg_dir, commit):
    rel = pkg_dir.relative_to(workdir).as_posix()
    parts = rel.split("/")
    if commit not in parts[0]:
        die(f"archive root {parts[0]} does not contain commit {commit}")
    parts[0] = parts[0].replace(commit, "%commit%", 1)
    return "/".join(parts)


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

lock_path = source_root / "Cargo.lock"
lock_text = ""
if lock_path.is_file():
    try:
        lock_text = lock_path.read_bytes().decode("utf-8")
    except UnicodeError:
        die(f"cannot parse Cargo.lock: {lock_path} is not utf-8")

adds = []
for dep_name, revs in sorted(workspace_git_deps(source_root).items()):
    if dep_name in known_names:
        continue
    recorded = sorted(
        rev for rev in revs if lock_text and lock_records(lock_text, dep_name, rev)
    )
    if not recorded:
        continue
    if len(recorded) != 1:
        die(f"multiple lock commits for {dep_name}")
    rev = recorded[0]
    matches = find_matches(rev, dep_name)
    if len(matches) == 0:
        die(f"no checkout for {dep_name} rev {rev}")
    if len(matches) != 1:
        die(f"multiple checkouts for {dep_name} rev {rev}")
    _root, pkg_dir, urls = matches[0]
    if len(urls) != 1:
        die(f"GIT_CRATES url for {dep_name} rev {rev} is not unique")
    url = next(iter(urls))
    directory = percent_commit_dir(pkg_dir, rev)
    for field in (dep_name, url, rev, directory):
        if any(ch in field for ch in "\t\n\r"):
            die(f"cannot register {dep_name}")
    adds.append((dep_name, url, rev, directory))

for dep_name, url, rev, directory in adds:
    print(f"{dep_name}\t{url}\t{rev}\t{directory}")
PY
	) || die "rewrite [patch.*] git pins"

	local added_any=0
	if [[ -n ${added} ]]; then
		local aname aurl acommit adir
		while IFS=$'\t' read -r aname aurl acommit adir; do
			[[ -n ${aname} ]] || continue
			[[ -n ${aurl} && -n ${acommit} && -n ${adir} ]] ||
				die "rewrite [patch.*] git pins"
			GIT_CRATES[${aname}]="${aurl};${acommit};${adir}"
			added_any=1
		done <<< "${added}"
	fi
	if [[ ${added_any} -eq 1 ]]; then
		cargo_gen_config
	fi
}

fi
