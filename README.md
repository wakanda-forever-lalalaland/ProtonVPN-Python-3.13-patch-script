# ProtonVPN-Python-3.13-patch-script
Fixes ProtonVPN local agent RustPanic on Python 3.13 (Kali Linux)
# ProtonVPN Python 3.13 Patch Script

> Fixes the `RustPanic` crash in `python3-proton-vpn-local-agent` that prevents ProtonVPN from connecting on **Python 3.13** (Kali Linux rolling and other Debian-based distros).

---

## The Problem

Kali Linux rolling ships with **Python 3.13**, which is incompatible with the compiled Rust extension inside `python3-proton-vpn-local-agent 1.6.0-1+b1`.

When you try to connect, the VPN tunnel establishes successfully via OpenVPN, but is immediately torn down with the following panic:

```
thread 'tokio-runtime-worker' panicked at rustls/src/crypto/mod.rs:249:
Could not automatically determine the process-level CryptoProvider.
Call CryptoProvider::install_default() before this point to select a
provider manually, or make sure exactly one of the 'aws-lc-rs' and
'ring' features is enabled.

pyo3_async_runtimes.RustPanic: rust future panicked: unknown error
```

### Root Cause

The local agent is a secondary encrypted channel that runs on top of the VPN tunnel, used for premium features like NetShield, port forwarding, and certificate management. It is built with `rustls` (a Rust TLS library) compiled as a Python extension via PyO3.

The Rust binary was compiled **without explicitly specifying a `CryptoProvider`** (`aws-lc-rs` or `ring`). Python 3.12 and earlier silently handled this, but **Python 3.13 exposes it as a hard panic**, tearing down the connection immediately after it is established.

### Affected Files

```
/usr/lib/python3/dist-packages/proton/vpn/backend/networkmanager/core/localagent_mixin.py
```

### Affected Methods

| Method | Description |
|---|---|
| `_start_local_agent_listener` | Async method that starts the Rust local agent |
| `_async_start_local_agent_listener` | Schedules the local agent on connect |
| `_async_stop_local_agent_listener` | Cleans up the local agent on disconnect |

---

## The Fix

The patch stubs out all three local agent methods so they return immediately, preventing the Rust extension from ever being invoked. The OpenVPN tunnel itself is unaffected and connects normally.

> **Note:** This disables premium local agent features (NetShield, port forwarding). For free-tier Proton VPN users, nothing is lost.

---

## Usage

### 1. Clone this repository

```bash
git clone https://github.com/wakanda-forever-lalalaland/ProtonVPN-Python-3.13-patch-script.git
cd ProtonVPN-Python-3.13-patch-script
```

### 2. Make the script executable

```bash
chmod +x fix-protonvpn.sh
```

### 3. Run the patch

```bash
./fix-protonvpn.sh
```

### 4. Hold the package to prevent apt from overwriting the patch

```bash
sudo apt-mark hold python3-proton-vpn-local-agent
```

---

## Reverting the Patch

When Proton releases a fix for Python 3.13 compatibility, unhold and upgrade:

```bash
sudo apt-mark unhold python3-proton-vpn-local-agent
sudo apt upgrade python3-proton-vpn-local-agent
```

---

## Environment

| Component | Version |
|---|---|
| OS | Kali Linux (rolling) |
| Python | 3.13.12 |
| ProtonVPN App | `proton-vpn-gnome-desktop 0.10.1` |
| Local Agent | `python3-proton-vpn-local-agent 1.6.0-1+b1` |
| Protocol | OpenVPN UDP |

---

## Reporting to Proton

This bug has been reported to Proton via their in-app bug reporter. If you are also affected, please report it to help prioritize the fix:

- In the ProtonVPN app: **Menu → Report an Issue**
- GitHub: [ProtonVPN/proton-vpn-gtk-app/issues](https://github.com/ProtonVPN/proton-vpn-gtk-app/issues)

---

## License

MIT — see [LICENSE](./LICENSE)
