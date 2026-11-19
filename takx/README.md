# TAKX installer wrapper

`install-takx.sh` installs TAKX (for example TAKX-CIV) from its install4j shell installer, `takx-unix-jdk*-<version>.sh`, on machines that are not x86-64, such as a Raspberry Pi 5 or another arm64 box. It also works on x86-64.

What it changes compared with running the installer directly:

- **arm64:** skips the installer's bundled x64 Java and uses a system JDK 17 instead. The installer accepts only Java 17, not 11 or 21.
- **Unattended:** installs with no prompts and no display by default (`--console` or `--gui` to change).
- **One folder per variant:** writes a varfile so each variant gets its own install dir (`/opt/<variant>`) and data dir (`/opt/<variant>-data`), and creates no `/usr/local/bin` symlinks, menu entries or desktop link. Installing several variants never overwrites one another.
- **Root:** the installer only runs as root, so the script re-runs itself with sudo. `--dry-run` never needs root.

## Usage

The script looks for the installer in its own folder. From this repo, point it at the installer instead:

```bash
./takx/install-takx.sh --installer /path/to/takx-unix-jdk17-<version>.sh --dry-run   # preview
./takx/install-takx.sh --installer /path/to/takx-unix-jdk17-<version>.sh             # install
```

Run `./takx/install-takx.sh --help` for every option (paths, Java, mode, temp dir).

## Java 17

On a system JDK (always on arm64, or with `--system-java`) the script finds a Java 17 itself, and **installs one with apt if there is none** (it needs root, which it already asks for with sudo; `--no-install-java` turns this off):

| OS | Java 17 source |
|---|---|
| Ubuntu 22.04, Ubuntu 24.04, Debian 12 | the OS's own `openjdk-17-jdk`, `-jdk-headless`, `-jre`, `-jre-headless` |
| Debian 13 (trixie), Raspberry Pi OS trixie | Debian 13 has no OpenJDK 17, so the Azul Zulu apt repository is added and `zulu17-jdk`, `zulu17-jdk-headless`, `zulu17-jre`, `zulu17-jre-headless` are installed (amd64 and arm64) |

To use a JDK 17 you already have somewhere else, pass `--java-home /path/to/jdk-17`.

## arm64: the bundled runtime

The installer carries an x64 Java runtime. On arm64 the script tells the installer not to use it, and after the install, if `<install dir>/jre` is an x64 runtime, it moves it to `jre.x64` and links `jre` to the arm64 JDK 17.
