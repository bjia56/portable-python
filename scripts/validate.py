"""Validate a portable-python distribution.

Run with the distribution's own interpreter, from inside the extracted
distribution directory:

    ./bin/python scripts/validate.py --os linux --arch x86_64 --distribution full

Exits non-zero if any check fails. Checks, in order:

  1. required extension modules are present (a missing module is a failure,
     not a skip)
  2. bundled dependency versions match what the build scripts pin
  3. functional smoke tests of the bundled libraries
  4. every importable module imports cleanly
  5. the shipped binaries only link against allowed system libraries and stay
     under the glibc symbol ceiling (ELF and Mach-O only)

Update the tables below when a dependency pin or platform support changes.
"""

import argparse
import importlib
import multiprocessing
import os
import pkgutil
import re
import struct
import sys
import time

RED = "\u001b[31m"
GREEN = "\u001b[32m"
RESET = "\u001b[0m"

FAILURES = []


def fail(msg):
    FAILURES.append(msg)
    print(f"{RED}FAIL: {msg}{RESET}")


def ok(msg):
    print(f"{GREEN}ok: {msg}{RESET}")


def check(cond, msg):
    if cond:
        ok(msg)
    else:
        fail(msg)


# ---------------------------------------------------------------------------
# Expectations
# ---------------------------------------------------------------------------

# Extension modules that must import on every platform.
REQUIRED_ALL = [
    "_bz2", "_ctypes", "_decimal", "_hashlib", "_lzma", "_sqlite3", "_ssl",
    "pyexpat", "zlib", "binascii", "select", "_socket", "unicodedata",
]
# Modules built from third-party libs that are absent on Windows.
REQUIRED_POSIX = ["_curses", "_curses_panel", "_dbm", "_gdbm", "readline", "_uuid", "fcntl", "termios"]
REQUIRED_WINDOWS = ["winreg", "msvcrt", "_overlapped"]
# Only in the "full" distribution (Tcl/Tk). Not shipped for cosmo.
REQUIRED_FULL = ["_tkinter", "tkinter"]
# Not available on these OS names; checked by prefix.
NO_GDBM = ("cosmo",)

# Top-level modules that legitimately fail to import in some builds.
IMPORT_ALLOWED_FAILURES = {
    "headless": {"_tkinter", "tkinter", "turtle", "turtledemo", "idlelib"},
    "full": set(),
    "-": {"_tkinter", "tkinter", "turtle", "turtledemo", "idlelib"},
}
IMPORT_SKIP = {"antigravity", "this", "__main__", "__phello__"}

# Dependency pins. Keep in sync with the build scripts.
EXPECTED_SQLITE = "3.45.0"
EXPECTED_SQLITE_WINDOWS = "3.43.1"
EXPECTED_ZLIB = "1.3.1"
EXPECTED_EXPAT = "2.6.2"
EXPECTED_OPENSSL_OLD = "1.1.1w"  # Python < 3.11
EXPECTED_OPENSSL_NEW = "3.0.15"  # Python >= 3.11

# Highest glibc symbol version each arch may require (zig -target ...gnu.X.Y).
GLIBC_CEILING = {
    "x86_64": (2, 17), "i386": (2, 17), "aarch64": (2, 17), "arm": (2, 17),
    "s390x": (2, 19), "powerpc64le": (2, 19),
    "riscv64": (2, 27), "loongarch64": (2, 36),
}

# System libraries a binary may link against (matched on the soname prefix).
ELF_ALLOWED_NEEDED = (
    "libc.so", "libm.so", "libdl.so", "libpthread.so", "librt.so",
    "libutil.so", "libcrypt.so", "libgcc_s.so", "ld-linux", "ld64.so",
    "linux-vdso", "libresolv.so", "libnsl.so",
)
MACHO_ALLOWED_PREFIXES = (
    "/usr/lib/libSystem", "/usr/lib/libc++", "/usr/lib/libncurses",
    "/usr/lib/libresolv", "/usr/lib/libz.", "/usr/lib/libiconv",
    "/System/Library/Frameworks/", "@rpath/", "@loader_path/", "@executable_path/",
)


def version_tuple(s):
    return tuple(int(p) for p in re.findall(r"\d+", s)[:3])


# ---------------------------------------------------------------------------
# 1. Required modules
# ---------------------------------------------------------------------------

def required_modules(os_name, distribution):
    mods = list(REQUIRED_ALL)
    if os_name == "windows":
        mods += REQUIRED_WINDOWS
    else:
        posix = list(REQUIRED_POSIX)
        if os_name in NO_GDBM:
            posix.remove("_gdbm")
        mods += posix
    if distribution == "full" and os_name != "cosmo":
        mods += REQUIRED_FULL
    return mods


def check_required_modules(os_name, distribution):
    print("== Required modules")
    for m in required_modules(os_name, distribution):
        try:
            importlib.import_module(m)
            ok(f"import {m}")
        except Exception as e:
            fail(f"required module {m} failed to import: {e!r}")
    if distribution == "headless" and os_name != "cosmo":
        try:
            importlib.import_module("_tkinter")
            fail("headless distribution unexpectedly contains _tkinter")
        except ImportError:
            ok("headless distribution has no _tkinter")


# ---------------------------------------------------------------------------
# 2. Versions
# ---------------------------------------------------------------------------

def check_versions(os_name):
    print("== Bundled dependency versions")
    import ssl
    import sqlite3
    import zlib
    import pyexpat

    expected_ssl = EXPECTED_OPENSSL_OLD if sys.version_info < (3, 11) else EXPECTED_OPENSSL_NEW
    m = re.search(r"OpenSSL (\S+)", ssl.OPENSSL_VERSION)
    got = m.group(1) if m else ssl.OPENSSL_VERSION
    check(got == expected_ssl, f"OpenSSL {got} (expected {expected_ssl})")

    expected_sqlite = EXPECTED_SQLITE_WINDOWS if os_name == "windows" else EXPECTED_SQLITE
    check(sqlite3.sqlite_version == expected_sqlite,
          f"SQLite {sqlite3.sqlite_version} (expected {expected_sqlite})")

    check(zlib.ZLIB_RUNTIME_VERSION.startswith(EXPECTED_ZLIB),
          f"zlib {zlib.ZLIB_RUNTIME_VERSION} (expected {EXPECTED_ZLIB})")

    got = ".".join(str(p) for p in pyexpat.version_info)
    check(got == EXPECTED_EXPAT, f"expat {got} (expected {EXPECTED_EXPAT})")


# ---------------------------------------------------------------------------
# 3. Functional smoke tests
# ---------------------------------------------------------------------------

def smoke(name, fn):
    try:
        fn()
        ok(name)
    except Exception as e:
        fail(f"{name}: {e!r}")


def check_functionality(os_name, distribution):
    print("== Functional smoke tests")
    import bz2, ctypes, decimal, hashlib, lzma, sqlite3, ssl, zlib
    import xml.etree.ElementTree as ET

    data = os.urandom(4096) + b"portable-python" * 100

    def roundtrip():
        assert zlib.decompress(zlib.compress(data)) == data
        assert bz2.decompress(bz2.compress(data)) == data
        assert lzma.decompress(lzma.compress(data)) == data
    smoke("zlib/bz2/lzma round trip", roundtrip)

    def hashing():
        assert hashlib.sha256(b"abc").hexdigest().startswith("ba7816bf")
        assert hashlib.sha3_256(b"abc").hexdigest().startswith("3a985da7")
        assert hashlib.blake2b(b"abc").hexdigest().startswith("ba80a53f")
    smoke("hashlib", hashing)

    def tls():
        ctx = ssl.create_default_context()
        assert ctx.cert_store_stats()["x509_ca"] > 0, "no CA certificates loaded"
        assert ssl.HAS_TLSv1_2
    smoke("ssl default context with CA bundle", tls)

    def sqlite():
        con = sqlite3.connect(":memory:")
        con.execute("create table t(a, b)")
        con.execute("insert into t values (1, 'x')")
        assert con.execute("select a from t").fetchone() == (1,)
        con.execute("create virtual table f using fts5(body)")
        con.execute("select json('[1,2]')")
        con.close()
    smoke("sqlite3 with FTS5 and JSON", sqlite)

    def xml():
        root = ET.fromstring("<a><b>1</b></a>")
        assert root.find("b").text == "1"
    smoke("pyexpat / ElementTree", xml)

    def ffi():
        lib = ctypes.CDLL("msvcrt") if os_name == "windows" else ctypes.CDLL(None)
        assert lib is not None
        assert ctypes.sizeof(ctypes.c_void_p) == struct_pointer_size()
        cb = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)(lambda x: x + 1)
        assert cb(1) == 2
    smoke("ctypes / libffi", ffi)

    def dec():
        assert decimal.Decimal("1.1") + decimal.Decimal("2.2") == decimal.Decimal("3.3")
    smoke("decimal", dec)

    if os_name != "windows":
        def curses():
            import _curses
            assert _curses.version
        smoke("_curses", curses)

        def dbm_():
            import dbm.gnu, tempfile
            with tempfile.TemporaryDirectory() as d:
                db = dbm.gnu.open(os.path.join(d, "x.db"), "c")
                db[b"k"] = b"v"
                assert db[b"k"] == b"v"
                db.close()
        if os_name not in NO_GDBM:
            smoke("dbm.gnu", dbm_)

    def pip_():
        import pip  # noqa: F401
    smoke("pip importable", pip_)

    def certifi_():
        import certifi
        assert os.path.exists(certifi.where())
    smoke("certifi bundled CA file exists", certifi_)

    if distribution == "full" and os_name != "cosmo":
        def tk():
            import tkinter
            assert tkinter.TclVersion >= 8.6
            interp = tkinter.Tcl()
            assert interp.eval("expr {1 + 1}") == "2"
        smoke("tkinter Tcl interpreter", tk)


def struct_pointer_size():
    return struct.calcsize("P")


# ---------------------------------------------------------------------------
# 4. Import everything
# ---------------------------------------------------------------------------

def _import_worker(name, q):
    try:
        importlib.import_module(name)
        q.put(None)
    except BaseException as e:  # noqa: BLE001
        import traceback
        q.put(f"{e!r}\n{traceback.format_exc()}")


def import_with_timeout(name, timeout=10):
    q = multiprocessing.Queue()
    p = multiprocessing.Process(target=_import_worker, args=(name, q))
    p.start()
    start = time.time()
    # Not using p.join() here: Cosmopolitan libc doesn't seem to react to the
    # child's exit on Windows.
    while p.is_alive():
        if time.time() - start > timeout:
            p.terminate()
            p.join()
            return f"timed out after {timeout} seconds"
        time.sleep(0.1)
    return q.get()


def check_imports(distribution):
    print("== Import all modules")
    allowed = IMPORT_ALLOWED_FAILURES.get(distribution, set())
    names = {m.name for m in pkgutil.iter_modules()} | set(sys.builtin_module_names)
    for name in sorted(names - IMPORT_SKIP):
        err = import_with_timeout(name)
        if err is None:
            ok(f"import {name}")
        elif name in allowed:
            print(f"skipped (allowed failure): {name}")
        else:
            fail(f"import {name}: {err}")

    import urllib.request
    try:
        urllib.request.urlopen("https://github.com", timeout=30).close()
        ok("urllib HTTPS fetch")
    except Exception as e:
        fail(f"urllib HTTPS fetch: {e!r}")


# ---------------------------------------------------------------------------
# 5. Binary portability (ELF / Mach-O)
# ---------------------------------------------------------------------------

def iter_binaries(root, suffixes):
    for dirpath, _, files in os.walk(root):
        for f in files:
            if f.endswith(suffixes) or ".so." in f or f in ("python", "python3"):
                p = os.path.join(dirpath, f)
                if os.path.islink(p) or not os.path.isfile(p):
                    continue
                yield p


def read_elf(path):
    """Return (needed sonames, set of glibc versions required) or None."""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"\x7fELF":
        return None
    is64 = data[4] == 2
    end = "<" if data[5] == 1 else ">"
    if is64:
        phoff, = struct.unpack_from(end + "Q", data, 0x20)
        phentsize, phnum = struct.unpack_from(end + "HH", data, 0x36)
    else:
        phoff, = struct.unpack_from(end + "I", data, 0x1C)
        phentsize, phnum = struct.unpack_from(end + "HH", data, 0x2A)

    loads, dyn = [], None
    for i in range(phnum):
        off = phoff + i * phentsize
        if is64:
            p_type, _, p_offset, p_vaddr, _, p_filesz, _, _ = struct.unpack_from(end + "IIQQQQQQ", data, off)
        else:
            p_type, p_offset, p_vaddr, _, p_filesz, _, _, _ = struct.unpack_from(end + "IIIIIIII", data, off)
        if p_type == 1:
            loads.append((p_vaddr, p_offset, p_filesz))
        elif p_type == 2:
            dyn = (p_offset, p_filesz)
    if dyn is None:
        return [], set()

    def v2o(vaddr):
        for va, po, sz in loads:
            if va <= vaddr < va + sz:
                return po + vaddr - va
        raise ValueError(f"unmapped address {vaddr:#x}")

    entsize = 16 if is64 else 8
    fmt = end + ("qQ" if is64 else "iI")
    tags = {}
    needed_offs = []
    off, size = dyn
    for i in range(size // entsize):
        tag, val = struct.unpack_from(fmt, data, off + i * entsize)
        if tag == 0:
            break
        if tag == 1:
            needed_offs.append(val)
        else:
            tags[tag] = val
    strtab = v2o(tags[5]) if 5 in tags else None

    def cstr(o):
        e = data.index(b"\0", o)
        return data[o:e].decode()

    needed = [cstr(strtab + o) for o in needed_offs] if strtab is not None else []

    glibc = set()
    # DT_VERNEED = 0x6ffffffe, DT_VERNEEDNUM = 0x6fffffff
    if 0x6ffffffe in tags and strtab is not None:
        off = v2o(tags[0x6ffffffe])
        for _ in range(tags.get(0x6fffffff, 0)):
            _, cnt, file_, aux, nxt = struct.unpack_from(end + "HHIII", data, off)
            aoff = off + aux
            for _ in range(cnt):
                _, _, _, name, anext = struct.unpack_from(end + "IHHII", data, aoff)
                n = cstr(strtab + name)
                if n.startswith("GLIBC_"):
                    glibc.add(version_tuple(n))
                aoff += anext
            off += nxt
    return needed, glibc


def check_elf(root, arch):
    print("== ELF dependencies")
    ceiling = GLIBC_CEILING.get(arch)
    for path in iter_binaries(root, (".so",)):
        try:
            res = read_elf(path)
        except Exception as e:
            fail(f"{path}: could not parse ELF: {e!r}")
            continue
        if res is None:
            continue
        needed, glibc = res
        rel = os.path.relpath(path, root)
        for n in needed:
            if not n.startswith(ELF_ALLOWED_NEEDED) and not n.startswith("libpython"):
                fail(f"{rel} links against unexpected library {n}")
        if ceiling and glibc and max(glibc) > ceiling:
            fail(f"{rel} requires GLIBC_{'.'.join(map(str, max(glibc)))}, above ceiling {'.'.join(map(str, ceiling))}")
    ok("ELF scan complete")


def read_macho_deps(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic = data[:4]
    slices = []
    if magic in (b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"):
        n, = struct.unpack_from(">I", data, 4)
        for i in range(n):
            _, _, off, size, _ = struct.unpack_from(">5I", data, 8 + i * 20)
            slices.append(data[off:off + size])
    else:
        slices.append(data)
    deps = set()
    for s in slices:
        m = s[:4]
        if m == b"\xcf\xfa\xed\xfe":
            hdr, end = 32, "<"
        elif m == b"\xce\xfa\xed\xfe":
            hdr, end = 28, "<"
        else:
            continue
        ncmds, = struct.unpack_from(end + "I", s, 16)
        off = hdr
        for _ in range(ncmds):
            cmd, size = struct.unpack_from(end + "II", s, off)
            # LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB, LC_LOAD_UPWARD_DYLIB
            if cmd in (0xC, 0x80000018, 0x8000001F, 0x80000023):
                name_off, = struct.unpack_from(end + "I", s, off + 8)
                name = s[off + name_off:off + size].split(b"\0")[0].decode()
                deps.add(name)
            off += size
    return deps


def check_macho(root):
    print("== Mach-O dependencies")
    for path in iter_binaries(root, (".so", ".dylib")):
        try:
            deps = read_macho_deps(path)
        except Exception as e:
            fail(f"{path}: could not parse Mach-O: {e!r}")
            continue
        rel = os.path.relpath(path, root)
        for d in deps:
            if not d.startswith(MACHO_ALLOWED_PREFIXES):
                fail(f"{rel} links against unexpected library {d}")
    ok("Mach-O scan complete")


def check_portability(os_name, arch):
    root = os.path.dirname(os.path.dirname(os.path.realpath(sys.executable)))
    if os_name == "linux":
        check_elf(root, arch)
    elif os_name == "darwin":
        check_macho(root)
    elif os_name.startswith(("freebsd", "solaris")):
        # Only the ELF dependency allowlist is useful here; libc names differ.
        print(f"(skipping binary portability checks on {os_name})")
    else:
        print(f"(no binary portability checks for {os_name})")


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--os", required=True, help="linux, darwin, windows, freebsd*, solaris*, cosmo")
    ap.add_argument("--arch", default="")
    ap.add_argument("--distribution", default="headless", help="full, headless, or -")
    args = ap.parse_args()

    print(sys.version)
    check_required_modules(args.os, args.distribution)
    check_versions(args.os)
    check_functionality(args.os, args.distribution)
    check_portability(args.os, args.arch)
    check_imports(args.distribution)

    if FAILURES:
        print(f"\n{RED}{len(FAILURES)} validation failure(s):{RESET}")
        for f in FAILURES:
            print(f"  - {f}")
        return 1
    print(f"\n{GREEN}All validation checks passed{RESET}")
    return 0


if __name__ == "__main__":
    multiprocessing.freeze_support()
    sys.exit(main())
