# memo Docker image

A self-contained Docker image for building PDFs from Markdown using the
[memo](https://github.com/ar/memo) toolchain. Everything needed to produce a
document — Pandoc, XeLaTeX, mermaid-filter, the Eisvogel template, and the
`memo` helper script itself — is baked into the image. You only need Docker on
the machine where you want to build.

## What's inside the image

| Component | Purpose |
|---|---|
| TeX Live (targeted) | XeLaTeX engine plus the packages required by memo and Eisvogel |
| Pandoc | Markdown → TeX / PDF conversion |
| M4 | Preprocessor for variable injection (dates, git revision, …) |
| mermaid-filter | Renders Mermaid diagrams embedded in Markdown |
| Chromium | Headless browser used by mermaid-filter via Puppeteer |
| pandoc-latex-environment | Enables styled admonition blocks (note, tip, warning, …) |
| Eisvogel template | Installed as `custom_eisvogel`, the name the `memo` script expects |
| ieee-with-url.csl | Citation style used for bibliography |
| `bin/memo` + `backgrounds/` | The memo script and default title-page background, copied from this repo |

## TeX Live

The image is based on [`texlive/texlive:latest`](https://hub.docker.com/r/texlive/texlive),
the official Docker image maintained by the TeX Live team. It ships with a
complete TeX Live installation already baked in, so there is nothing to install
at build time — the heavy layer is pulled once and reused on every subsequent
build.

## Building the image

Run this from the **repo root** (the build context must include `bin/` and
`backgrounds/`):

```bash
docker build -f docker/Dockerfile -t memo .
```

Use `docker build`, not `docker buildx build`. The `buildx` command uses the
`docker-container` driver by default, which doesn't load the result into the
local image store (you'd get a `No output specified` warning and an EOF error).
Plain `docker build` uses the `docker` driver, which loads the image
automatically and still supports BuildKit cache mounts.

If you are on Docker older than 23, enable BuildKit explicitly:

```bash
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t memo .
```

**First build:** Docker pulls the `texlive/texlive` base image (~5 GB) and
installs the remaining tools (pandoc, Node, Chromium, etc.). This takes a few
minutes, mostly on the pull.

**Subsequent builds:** the base image layer is already cached locally, and
BuildKit cache mounts keep apt, npm, and pip package downloads cached between
runs. Only layers that actually changed are re-executed, so rebuilds after
editing the Dockerfile are fast.

## Usage

Mount the directory containing your `.md` file to `/work` inside the container
and pass the filename as an argument:

```bash
docker run --rm -v $(pwd):/work memo myfile.md
```

The PDF is written back to the same directory (i.e. your local `$(pwd)`).

### Layout

An optional second positional argument controls the column layout:

```bash
# Single-column (default)
docker run --rm -v $(pwd):/work memo myfile.md single

# Two-column
docker run --rm -v $(pwd):/work memo myfile.md double
```

### All options

```
Usage: memo [options] file.md [single|double]

  --info          Verbose logging to <file>_processing.log
  --tex           Force TeX intermediate (Pandoc → TeX → XeLaTeX)
  --glossary      Build LaTeX glossaries (3-pass XeLaTeX)
  --nomenclature  Build LaTeX nomenclature (3-pass XeLaTeX)
  --keep          Keep intermediate files after the build
  --clean         Remove intermediate files and exit without building
  -DNAME=VALUE    Pass an m4 define (repeatable)
```

Examples:

```bash
# Verbose build with glossary support
docker run --rm -v $(pwd):/work memo report.md --info --glossary

# Two-column layout with a custom m4 variable
docker run --rm -v $(pwd):/work memo report.md double -DVERSION=1.4

# Clean up leftover intermediate files
docker run --rm -v $(pwd):/work memo report.md --clean
```

## Document frontmatter

The `memo` script uses Pandoc's YAML front matter for document metadata. Here
is the frontmatter from the example document as a starting point:

```yaml
---
title: My Document
subject: Some Subject
author: Your Name
date: 2024-01-01
titlepage: true
toc: true
toc-own-page: true
footer-center: My Footer (__REVISION__)
titlepage-rule-color: "360049"
titlepage-text-color: "FFFFFF"
titlepage-rule-height: 0
titlepage-background: "backgrounds/background.pdf"
footnotes-pretty: true
header-includes:
  - \usepackage{multicol}
  - \usepackage{fontawesome5}

pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]
---
```

### Title-page background

The frontmatter above references `backgrounds/background.pdf` as a relative
path. The entrypoint script handles this automatically: if your working
directory does not have a `backgrounds/` folder, it creates a symlink pointing
to the default background bundled in the image (`/opt/memo/backgrounds/`).

To use your own background, place a `backgrounds/` folder next to your `.md`
file before running the container — the symlink is only created when that
folder is absent.

### m4 variables

The preprocessor injects the following variables automatically. You can
reference them anywhere in your Markdown:

| Variable | Value |
|---|---|
| `__DATE__` | Build date (`YYYY-MM-DD`) |
| `__TIME__` | Build time (`HH:MM`) |
| `__BRANCH__` | Git branch name |
| `__REVISION__` | Short git commit hash (with `*` if dirty) |
| `__TAG__` | Git tag or short hash |
| `__FILENAME__` | Absolute path of the source file |

You can also define your own with `-DNAME=VALUE`:

```bash
docker run --rm -v $(pwd):/work memo doc.md -DRELEASE=2.0
```

## Convenience alias

Add this to your shell profile to avoid typing the full `docker run` command
every time:

```bash
alias memo='docker run --rm -v $(pwd):/work memo'
```

Then just use:

```bash
memo myfile.md
memo myfile.md double --glossary
```
