FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0@sha256:63ef5dda2fb5681ae3aa5c9597a8c4b24364da91ec459b419fa3c38160595fae AS tools

ARG TARGETARCH
ARG USER_UID=1000
ARG USER_GID=1000
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN dnf install -y --setopt=install_weak_deps=0 \
    azure-cli-2.91.0 graphviz dos2unix librsvg2-tools ca-certificates \
    liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts \
    alsa-lib at-spi2-atk at-spi2-core atk cairo cups-libs dbus-libs expat \
    fontconfig mesa-libgbm libgcc gdk-pixbuf2 glib2 gtk3 nspr nss pango \
    libstdc++ libX11 libX11-xcb libxcb libXcomposite libXcursor libXdamage \
    libXext libXfixes libXi libXrandr libXrender libxshmfence libXtst xdg-utils \
    git sudo shadow-utils tar gzip unzip xz which procps-ng util-linux \
    openssl-libs libicu libuuid krb5-libs zlib jq curl zsh gawk wget2-wget \
    gcc gcc-c++ make python3 \
    && dnf clean all \
    && groupadd --gid "$USER_GID" vscode \
    && useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/bash vscode \
    && printf 'vscode ALL=(root) NOPASSWD:ALL\n' > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

ENV NVM_DIR=/usr/local/share/nvm \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    PLAYWRIGHT_BROWSERS_PATH=/opt/browsers/playwright \
    PUPPETEER_CACHE_DIR=/opt/browsers/puppeteer \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MPLCONFIGDIR=/home/vscode/.cache/matplotlib \
    AZURE_BICEP_USE_BINARY_FROM_PATH=true \
    AZURE_CORE_COLLECT_TELEMETRY=false
ENV PATH="/opt/csa-toolkit/.venv/bin:/opt/csa-toolkit/node_modules/.bin:/usr/local/share/nvm/current/bin:${PATH}"

COPY tool-versions.env releases.sha256 install-tools.sh install-az-modules.ps1 /opt/csa-toolkit/
RUN bash /opt/csa-toolkit/install-tools.sh "$TARGETARCH"
RUN DOTNET_SYSTEM_NET_HTTP_SOCKETSHTTPHANDLER_HTTP2SUPPORT=0 \
    pwsh -NoProfile -File /opt/csa-toolkit/install-az-modules.ps1

FROM tools AS toolkit
ENV COREPACK_HOME=/home/vscode/.cache/corepack COREPACK_DEFAULT_TO_LATEST=0
ENV npm_config_registry=https://packagefeedproxy.microsoft.io/npm/ \
    PNPM_CONFIG_REGISTRY=https://packagefeedproxy.microsoft.io/npm/ \
    COREPACK_NPM_REGISTRY=https://packagefeedproxy.microsoft.io/npm/ \
    YARN_NPM_REGISTRY_SERVER=https://packagefeedproxy.microsoft.io/npm/ \
    UV_DEFAULT_INDEX=https://packagefeedproxy.microsoft.io/pypi/simple/
COPY pyproject.toml uv.lock package.json package-lock.json .npmrc /opt/csa-toolkit/
WORKDIR /opt/csa-toolkit
RUN source tool-versions.env \
    && uv python install "$PYTHON_VERSION" \
    && uv sync --locked --no-dev --python "$PYTHON_VERSION" \
    && npm ci --ignore-scripts \
    && chmod +x node_modules/pnpm/bin/pnpm.mjs node_modules/pnpm/bin/pnpx.mjs \
    && ln -sf ../pnpm/bin/pnpm.mjs node_modules/.bin/pnpm \
    && ln -sf ../pnpm/bin/pnpx.mjs node_modules/.bin/pnpx \
    && chmod +x node_modules/@yarnpkg/cli-dist/bin/yarn.js \
    && ln -sf ../@yarnpkg/cli-dist/bin/yarn.js node_modules/.bin/yarn \
    && ln -sf ../@yarnpkg/cli-dist/bin/yarn.js node_modules/.bin/yarnpkg \
    && puppeteer browsers install \
    && playwright install chromium \
    && chmod -R a+rX /opt/python /opt/browsers /opt/csa-toolkit

COPY smoke-test.sh smoke-test.py smoke-browser.cjs /opt/csa-toolkit/
ENV AZURE_AUTO_UPGRADE_ENABLE=false
RUN mkdir -p /home/vscode/.cache/uv /home/vscode/.config/gh \
    && chown -R vscode:vscode /home/vscode
USER vscode
WORKDIR /home/vscode
CMD ["sleep", "infinity"]
