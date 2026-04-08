# Use the official TeX Live image as base — TeX Live is already installed,
# so there is no 30-minute apt install on every build. The heavy layer is
# pulled once and cached by Docker.
FROM texlive/texlive:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install non-TeX dependencies.
# BuildKit cache mount keeps the apt cache across builds so packages are not
# re-downloaded when this layer is invalidated.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    # Pandoc
    pandoc \
    # M4 macro processor
    m4 \
    # Node.js + npm for mermaid-filter
    nodejs \
    npm \
    # Chromium for puppeteer (used by mermaid-filter)
    chromium \
    # pipx for pandoc-latex-environment
    pipx \
    # Misc
    curl \
    ca-certificates \
    git

# Tell puppeteer to use the system chromium instead of downloading its own
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# mermaid-filter (cache npm's download directory across builds)
RUN --mount=type=cache,target=/root/.npm \
    npm install -g mermaid-filter

# pandoc-latex-environment (cache pip's download directory across builds)
RUN --mount=type=cache,target=/root/.cache/pip \
    pipx install pandoc-latex-environment \
    && ln -s /root/.local/bin/pandoc-latex-environment /usr/local/bin/pandoc-latex-environment

# Pandoc templates directory
RUN mkdir -p /root/.local/share/pandoc/templates

# Eisvogel template installed as 'custom_eisvogel' (name the memo script expects).
# Use find to locate the .latex file regardless of the tarball's directory structure.
RUN curl -sSL \
    https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
    | tar -xz -C /tmp/ \
    && find /tmp -name "eisvogel*.latex" | head -1 \
       | xargs -I{} cp {} /root/.local/share/pandoc/templates/custom_eisvogel.latex \
    && rm -rf /tmp/eisvogel*

# ieee-with-url.csl (used by the memo script for bibliography)
RUN curl -sSL \
    https://raw.githubusercontent.com/citation-style-language/styles/master/ieee-with-url.csl \
    -o /root/.local/share/pandoc/templates/ieee-with-url.csl

# Copy the repo into the image so bin/memo, backgrounds/, etc. are all present.
# BASE_PATH in the memo script resolves to /opt/memo, which is correct.
COPY . /opt/memo/
RUN chmod +x /opt/memo/bin/memo

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /work

# Mount your document directory to /work and pass the .md file as argument:
#   docker build --build-arg BUILDKIT_INLINE_CACHE=1 -f docker/Dockerfile -t memo .
#   docker run --rm -v $(pwd):/work memo myfile.md [single|double] [options]
ENTRYPOINT ["/entrypoint.sh"]
