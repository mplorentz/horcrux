# Dockerfile for Cursor Cloud Agent
# Includes Dart/Flutter, Nostrbook MCP, and Marionette MCP

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    # Build tools for Linux desktop
    cmake \
    ninja-build \
    pkg-config \
    clang \
    # C++ standard library development files
    libstdc++-12-dev \
    # Linux desktop GUI development libraries (required by Flutter CMakeLists.txt)
    libgtk-3-dev \
    libglib2.0-dev \
    # Additional packages that may be required by plugins
    libpango1.0-dev \
    libcairo2-dev \
    libgdk-pixbuf2.0-dev \
    libatk1.0-dev \
    # Required by flutter_secure_storage_linux plugin
    libsecret-1-dev \
    libjsoncpp-dev \
    # Linux desktop GUI runtime libraries
    libglu1-mesa \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    # Virtual display for headless operation
    xvfb \
    # Screenshot tools
    x11-apps \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20+ (for npx/nostrbook MCP)
# Remove any conflicting packages first, then install from NodeSource
RUN apt-get update && \
    apt-get remove -y nodejs npm libnode-dev 2>/dev/null || true && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter 3.35.0
ENV FLUTTER_VERSION=3.35.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
RUN mkdir -p /root/.flutter /root/.pub-cache

RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter doctor && \
    flutter config --enable-linux-desktop

# Install Marionette MCP globally
RUN dart pub global activate marionette_mcp

# Install Nostrbook MCP (pre-cache via npx)
RUN npx -y @nostrbook/mcp@latest --help || true

# Set up working directory
WORKDIR /workspace

# Expose port for VM service
EXPOSE 8181

# Set up Xvfb display
ENV DISPLAY=:99

# Set default VM service port (can be overridden)
ENV FLUTTER_VM_SERVICE_PORT=8181

# Default command: keep container running
# Project files will be mounted as volume, dependencies installed on first run
CMD ["tail", "-f", "/dev/null"]
