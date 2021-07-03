# AUTOPACKAGER PACKAGING SPECS

Standard packaging guidelines for consistent, simple, end user and developer friendly.

## Spec Version

```
release-archives.autopackager.github.io/v1beta1
```

## Keywords

The key words _MUST_, _MUST NOT_, _REQUIRED_, _SHALL_, _SHALL NOT_, _SHOULD_, _SHOULD NOT_, _RECOMMENDED_, _MAY_, and _OPTIONAL_ in this document are to be interpreted as described in RFC 2119.

## Unix (tar.gz or tar.xz archive)

Following rules apply to Linux, macOS, FreeBSD, Solaris, OpenBSD etc.

1. Archive **MUST** be of `GNU tar 1.13.x format`
1. Archive **MUST** be compressed with `gzip` or `xz`
1. Files included **SHOULD NOT** contain acls. This makes sense in most of the cases, though there might be exceptions.
1. All files in archive **SHOULD** be within a directory. Archive cannot contain files at its root. For example, you can include `/docs/README.md` in your archive, but placing this `README.md` at root of the archive is not recommended.
1. Binaries, **SHOULD** be static. For embedding data files like server css and javascript and image assets, see [this for golang](https://golang.org/pkg/embed/) and [this for rust](https://github.com/pyros2097/rust-embed).
1. Archive **MUST** have following layout & permissions. You can however omit components you do not generate or require. This layout is designed to ease end user in installing not just the binary but shell completion and manpages easily with little effort. Installing fish completions now becomes simple tar command. `tar --extract --gzip --directory ~/.config/fish/completions/ --file awesome-cli-tool.tar.gz completions/fish`. This makes it simple to install stuff, and only the stuff end user needs and where they need it.

  | Directory | File Permissions (octal) | Contents
  |---|---|---
  | `bin` | 755 | Binaries and scripts.
  | `man/man{1..8}` | 644 | Default manpages.
  | `man/${ISO_639_1_LANG_CODE}/man{1..8}` | 644 | Localized manpages.
  | `completions/fish` | 644 | Fish shell completions
  | `completions/bash` | 644 | Bash completion files.
  | `completions/zsh` | 644 | ZSH completion files.
  | `completions/powershell` | 644 | Powershell completions.

## Windows (zip archive)

1. Archive **MUST** be of `ZIP` format
1. All files in archive **MUST** be within a directory. Archive cannot contain files at its root. For example, you can include `/docs/README.md` in your archive, but placing this `README.md` at root of the archive is not recommended.
1. Binaries, **SHOULD** be static. For embedding data files like server css and javascript and image assets, see [this for golang](https://golang.org/pkg/embed/) and [this for rust](https://github.com/pyros2097/rust-embed).
1. Archive **MUST** have following layout. All the folders mentioned are optional.

  | Directory | Contents
  |---|---
  | `bin` |  Binaries and scripts
  | `completions/bash` | Bash completion files.
  | `completions/powershell` | Powershell completions
