Run the packaging checks from the repository root:

```bash
python3 -m unittest discover -s tests -v
```

To include the binary integration tests, set `CADDY_ANALYZE_BIN` to the absolute
path of a compiled `caddy-analyze`:

```bash
CADDY_ANALYZE_BIN=/absolute/path/caddy-analyze python3 -m unittest discover -s tests -v
```

The tests check ebuild build and test phases, linker version injection, metadata,
completion failure handling, all completion USE flag combinations, CLI command
availability, JSON report fields, input ordering invariance, and invalid flags.
They isolate configuration in temporary directories and disable GeoIP downloads.
The ebuild's `test` USE flag runs the upstream Go suite, including the patched
GeoIP regression test. Upstream HTTP contract tests use local loopback servers.

For a version bump, generate the dependency archive from the tagged source with
the same Go toolchain requirement as `go.mod`:

```bash
GOMODCACHE="${PWD}/go-mod" go mod download -modcacherw
GOMODCACHE="${PWD}/go-mod" go mod verify
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    --use-compress-program='xz -T2 -9' \
    -cf caddy-analyzer-VERSION-vendor.tar.xz go-mod
```

Check each command's exit status before continuing. Publish the archive under
the release named `caddy-analyzer-VERSION` in the assets repository used by
`SRC_URI`, then regenerate the Manifest. Verify a build from freshly extracted
source and dependencies with `GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local`.
