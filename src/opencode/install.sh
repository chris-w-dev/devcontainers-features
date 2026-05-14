#!/bin/bash
set -e

CUSTOM_INIT_SCRIPT="${CUSTOMINITSCRIPT:-"init.ps1"}"
OPENCODE_MOUNT_PATH="/mnt/opencode"
OPENCODE_VOLUME_PATH="/var/opencode"

# Install base dependencies
apt update \
    && apt install -y --no-install-recommends \
    curl \
    rsync \
    unzip \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for OpenCode configuration
su - "$_REMOTE_USER" -c "ln -s /var/opencode/.config "$HOME/.config""
su - "$_REMOTE_USER" -c "ln -s /var/opencode/.local "$HOME/.local""

# Only install Bun if it is enabled
if [ "${INSTALLBUN}" = "true" ]; then
    su - "$_REMOTE_USER" -c "curl -fsSL https://bun.sh/install | bash"
fi

# Install OpenCode, either the latest version or a specific version if provided
if [ "${VERSION}" = "latest" ]; then
    su - "$_REMOTE_USER" -c "curl -fsSL https://opencode.ai/install | bash"
else
    su - "$_REMOTE_USER" -c "curl -fsSL https://opencode.ai/install | bash -s -- --version ${VERSION}"
fi

# Create initialization scripts from string to allow for dynamic content based on the feature's configuration options
cat > /usr/local/bin/init-opencode-auth \
<< EOF 
#!/bin/bash
# Initialization script for OpenCode configuration
set -e

# Copy OpenCode authentication from the mounted paths into the persistent state volume.
OPENCODE_STATE="${OPENCODE_VOLUME_PATH}/.local"
echo "📦 Copying OpenCode authentication to persistent state at \${OPENCODE_STATE}..."

mkdir -p "\$OPENCODE_STATE"
cp -a "${OPENCODE_MOUNT_PATH}/.local"/. "\$OPENCODE_STATE"/

echo "✅ Copied OpenCode authentication"
EOF

cat > /usr/local/bin/init-opencode \
<< EOF
#!/bin/bash
# Initialization script for OpenCode configuration
set -e

# Copy OpenCode configuration from the mounted paths into the persistent state volume.
if [ "${COPYLOCALCONFIGFOLDER}" = "true" ]; then
    OPENCODE_CONFIG="${OPENCODE_VOLUME_PATH}/.config"
    echo "📦 Copying OpenCode configuration to persistent state at \${OPENCODE_CONFIG}..."

    mkdir -p "\$OPENCODE_CONFIG"
    rsync -a "${OPENCODE_MOUNT_PATH}/.config"/ "\$OPENCODE_CONFIG"/

    echo "✅ Copied OpenCode configuration"
else
    mkdir -p "${OPENCODE_VOLUME_PATH}/.config/opencode"
fi

# Verify tool installations
echo ""
echo "🔧 Checking installed tools..."

# Check for Bun if it is enabled
if [ "${INSTALLBUN}" = "true" ]; then
    if command -v bun &> /dev/null; then
        echo "✅ Bun \$(bun --version)"
    else
        echo "⚠️  Bun not found"
    fi
fi

if command -v opencode &> /dev/null; then
    echo "✅ OpenCode \$(opencode --version)"
else
    echo "⚠️  OpenCode not found"
fi
    
# Run OpenCode init script if it exists
OPENCODE_ROOT="\$HOME/.config/opencode"
INIT_SCRIPT="\$OPENCODE_ROOT/$CUSTOM_INIT_SCRIPT"

# Check if OpenCode config is mounted
if [ -d "\$OPENCODE_ROOT" ]; then
    echo "✅ OpenCode config mounted at \$OPENCODE_ROOT"

    if [ -f "\$INIT_SCRIPT" ]; then
        echo ""
        echo "🔧 Running OpenCode init script..."
        pwsh -File "\$INIT_SCRIPT" -Root "\$OPENCODE_ROOT"
        echo "✅ OpenCode initialized"
    else
        echo "   No $CUSTOM_INIT_SCRIPT found, skipping OpenCode initialization"
    fi
else
    echo "⚠️  OpenCode config not found - some features may not work"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Available commands:"
echo "  opencode             - Start OpenCode AI assistant"
echo ""
EOF

chmod +x /usr/local/bin/init-opencode-auth
chmod +x /usr/local/bin/init-opencode
