#!/bin/bash

# Set DISPLAY environment variable
export DISPLAY=:99

# Start X server and VNC in the background
echo "Starting X server and VNC..."
Xvfb :99 -screen 0 ${RESOLUTION_WIDTH}x${RESOLUTION_HEIGHT}x24 &
x11vnc -display :99 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever -shared &
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Wait for X server to be ready
sleep 5

# Verify X server is running
echo "Verifying X server on DISPLAY=$DISPLAY..."
xdpyinfo -display :99 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ X server is running successfully"
else
    echo "❌ X server failed to start"
fi

# Check the mode and start the appropriate service
if [ "$BROWGENE_MODE" = "api" ]; then
    echo "DISPLAY is set to: $DISPLAY"
    # Start the v2 agentic server (browser-use 0.12) in the background on :8200.
    # Solvrays/PulseGene agentic mode targets http://svg-browgene:8200/api/v2.
    BROWGENE_V2_PORT="${BROWGENE_PORT:-8200}"
    echo "Starting BrowGene v2 agentic server on port ${BROWGENE_V2_PORT}..."
    BROWGENE_PORT="${BROWGENE_V2_PORT}" python -m api.server &
    # Start the legacy script API (Playwright, no LLM) in the foreground on :7793.
    echo "Starting BrowGene script API server on port ${API_PORT}..."
    exec python -m uvicorn api_server:app --host 0.0.0.0 --port ${API_PORT}
else
    echo "Starting BrowGene Gradio interface..."
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
fi
