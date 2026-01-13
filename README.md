# 📦 Pterodactyl Hytale Egg

A **production-ready Pterodactyl Egg** for hosting **Hytale** servers.  
This egg uses the **official Hytale Downloader**, handles **OAuth authentication**, extracts server files automatically, and starts the server cleanly with panel-friendly configuration.

Designed for **game server providers** and **self-hosters** who want a reliable, zero-guesswork setup.

---

## 🚀 Features

- ✅ Automatic server download using the official Hytale Downloader
- ✅ OAuth device authentication handled at runtime
- ✅ Automatic extraction of downloaded server files
- ✅ Clean and readable console output
- ✅ Safe, panel-tested variable validation
- ✅ Optional automatic backups
- ✅ Configurable authentication modes
- ✅ Proper startup detection for Pterodactyl
- ✅ Restart-safe and update-safe
- ✅ Debian 13 + Eclipse Temurin 25 compatible

---

## 🧠 Requirements

| Component | Version |
|---------|---------|
| Pterodactyl Panel | v1.x |
| Wings | Latest |
| Install Container | `debian:13-slim` |
| Runtime Image | `ghcr.io/luxxy-gf/temurin-25:latest` |
| Java | OpenJDK 25 (Temurin) |

---

## 🛠 Installation

1. Download or clone this repository
2. Import the Egg JSON into your Pterodactyl panel
3. Create a new server using the **Hytale Egg**
4. Ensure the following settings are used:
