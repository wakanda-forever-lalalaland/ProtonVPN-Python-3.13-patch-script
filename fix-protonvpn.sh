#!/bin/bash
# fix-protonvpn.sh
# Patches python3-proton-vpn-local-agent to work on Python 3.13
# See README.md for full details

FILE="/usr/lib/python3/dist-packages/proton/vpn/backend/networkmanager/core/localagent_mixin.py"

echo "[*] Checking if ProtonVPN local agent file exists..."
if [ ! -f "$FILE" ]; then
    echo "[!] File not found: $FILE"
    echo "    Make sure ProtonVPN is installed first."
    exit 1
fi

echo "[*] Checking if patch is already applied..."
if grep -q "disabled - Python 3.13 incompatible" "$FILE"; then
    echo "[!] Patch already applied. Nothing to do."
    exit 0
fi

echo "[*] Applying patch..."

sudo sed -i 's/        if self._agent_listener.is_running:/        return  # disabled - Python 3.13 incompatible\n        if self._agent_listener.is_running:/' "$FILE"

sudo sed -i 's/    def _async_start_local_agent_listener(self):/    def _async_start_local_agent_listener(self):\n        return  # disabled - Python 3.13 incompatible/' "$FILE"

sudo sed -i 's/    def _async_stop_local_agent_listener(self):/    def _async_stop_local_agent_listener(self):\n        return  # disabled - Python 3.13 incompatible/' "$FILE"

echo "[*] Verifying patch..."
MATCHES=$(grep -c "disabled - Python 3.13 incompatible" "$FILE")

if [ "$MATCHES" -eq 3 ]; then
    echo "[+] Patch applied successfully ($MATCHES stubs inserted)."
    echo "[+] ProtonVPN should now connect normally using OpenVPN."
    echo ""
    echo "[!] Remember to hold the package to prevent apt from overwriting the patch:"
    echo "    sudo apt-mark hold python3-proton-vpn-local-agent"
else
    echo "[!] Patch may not have applied correctly. Found $MATCHES/3 stubs."
    echo "    Check the file manually: $FILE"
    exit 1
fi
