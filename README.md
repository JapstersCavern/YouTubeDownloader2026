# 🎵 YouTube Downloader 2026

A GUI-Based Quality-Of-Life Helper Tool for yt-dlp / YouTube Downloader

A powerful, user-friendly YouTube downloader built on top of [yt-dlp](https://github.com/yt-dlp/yt-dlp), available as both a **GUI application** (Python/PySimpleGUI) and a **command-line batch script** (Windows).

Supports video, audio, chapter splitting, tracklist extraction, thumbnail embedding, and more — all with a clean dark-themed interface for the `*PYTHON*` app.

*PLEASE NOTE* that although the `*PYTHON*` based GUI tool gives access to ALL functionality as standard, the `*batch file / SCRIPT*` started life as a personal download helper tool, and it's currently just a snapshot of what turned out to be a very useful script-based automation tool!

As such, I've (currently) commented out parts of the script that *I* personally do not often use - feel free to uncomment options like `TRUNCATE / SNIP`, `KEEP original MP3 / MP4 file` (when extracting chapters etc), and so on...  😊

---

## ✨ Features

- 📋 **Clipboard URL detection** — automatically detects copied YouTube links
- 🎵 **Audio (MP3)** download at highest quality
- 🎬 **Video (MP4)** download at best available quality
- ✂️ **Clip / Snip** — download a specific time range
- 📂 **Chapter splitting** — split into individual MP3 or MP4 files per chapter
- 🖼️ **Folder thumbnail** — saves `folder.jpg` in every output folder
- 🎨 **Cover art embedding** — embeds thumbnail into every MP3 via ffmpeg
- 📋 **Tracklist extraction** — generates `tracklist.txt` from chapter markers or video description
- ⏱️ **Truncation support** — stop download at a specific time (great for repeated tracklists)
- 💾 **Last folder memory** — remembers your last used output folder
- 🔄 **Batch mode** — run again with same or new folder without restarting
- 🧹 **Auto cleanup** — removes all temporary files after each download

---

## 🖥️ Requirements

### Essential
| Tool | Purpose | Download |
|------|---------|----------|
| **yt-dlp** | Core downloader engine | [github.com/yt-dlp/yt-dlp/releases](https://github.com/yt-dlp/yt-dlp/releases) |
| **ffmpeg** | Audio conversion & thumbnail embedding | [ffmpeg.org/download.html](https://ffmpeg.org/download.html) or [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) |
| **Firefox** | Cookie authentication for YouTube | [mozilla.org/firefox](https://www.mozilla.org/firefox/) |
| **Python 3.9+** | Required for GUI version | [python.org/downloads](https://www.python.org/downloads/) |
| **Deno** | JavaScript runtime required by yt-dlp | [deno.com](https://deno.com/) |

### For GUI version only
```
pip install PySimpleGUI==4.60.5
```

> ⚠️ Use version **4.60.5** specifically to avoid licence nag screens in newer versions.

---

## 📁 File Setup

Place all of the following in the **same folder**:

```
📁 Your chosen folder (eg. C:\Tools\YTDownloader\)
├── yt-dlp.exe
├── deno.exe
├── YouTubeDownloader2026.py    ← GUI version
├── YouTubeDownloader2026.bat   ← Batch/CLI version
└── lastdir.txt                 ← Auto-created on first run
```

> **ffmpeg** should either be in the same folder, or added to your Windows PATH.  
> To add to PATH: Search *"Edit the system environment variables"* → Environment Variables → Path → New → paste ffmpeg's `bin` folder path.

---

## 🔐 One-Time Setup: YouTube Authentication

YouTube requires you to be logged in for many downloads. yt-dlp reads your Firefox session cookies to authenticate — you only need to do this **once**, and it persists until your session expires.

### Steps:
1. Open **Firefox**
2. Go to [youtube.com](https://www.youtube.com) and **sign in** to your Google/YouTube account
3. You can close Firefox after signing in — the cookies are saved to disk
4. When downloading, you may need to **close Firefox completely** before running the downloader
   - If you encounter issues reading FireFox's cookies, then just closing the window might not be enough — right-click the taskbar icon and choose **Exit**, or check the system tray *(Firefox may lock its cookie database while running)*
5. That's it — yt-dlp will read your saved cookies automatically

> 💡 You'll only need to repeat this if you're logged out of YouTube in Firefox, or if YouTube invalidates your session (usually every few weeks to months).

---

## 🚀 Running the GUI

```bash
python YouTubeDownloader2026.py
```

Or build a standalone executable (no Python needed to run):
```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name "YouTubeDownloader2026" YouTubeDownloader2026.py
```
The `.exe` will appear in the `dist\` folder.

---

## 🖱️ GUI Workflow

1. **Copy** a YouTube URL in your browser
2. Launch the app — it will **auto-detect** the clipboard URL
3. Click **📋 Paste URL** if needed, or type/paste manually
4. Click **🔍 Fetch Video Info** — this retrieves the title and metadata
5. Edit the **Folder / File name** if desired (or accept the suggested name)
6. Choose your **Output folder** (remembered between sessions)
7. Select a **Download mode**
8. Click **⬇ Download**
9. When complete, click **📂 Open Folder** to see your files

---

## ⌨️ Batch Script Workflow

1. **Copy** a YouTube URL in your browser
2. Double-click `YouTubeDownloader2026.bat`
3. Press **Enter** to use the detected clipboard URL, or paste a different one
4. Press **Enter** to reuse last folder, or type a new path
5. Press **Enter** to accept the suggested folder/file name, or type a custom one
6. Choose a download mode (1–5)
7. For chapter modes, optionally enter a truncation time
8. Wait for download to complete — folder opens automatically
9. Choose to run again (same folder / new folder) or exit

---

## 📥 Download Modes

| Mode | Output | Best for |
|------|--------|----------|
| **Audio (MP3)** | Single MP3 file | Music, podcasts, ambient mixes |
| **Video (MP4)** | Single MP4 file | Videos, tutorials |
| **Clip / Snip** | Single MP4 of a time range | Extracting a specific segment |
| **Split chapters (MP3)** | One MP3 per chapter | Albums, playlists with chapters |
| **Split chapters (MP4)** | One MP4 per chapter | Video series with chapters |

---

## 📂 Output Structure

For a video titled *"Cyberpunk Ambient Mix"* with chapters:

```
📁 Cyberpunk Ambient Mix/
├── 01 - Night Drive.mp3
├── 02 - Neon Rain.mp3
├── 03 - Signal Lost.mp3
├── ...
├── folder.jpg          ← Album art thumbnail
└── tracklist.txt       ← Auto-generated track listing
```

**tracklist.txt** example:
```
01. Night Drive - 0:00:00
02. Neon Rain - 0:03:45
03. Signal Lost - 0:08:12
```

---

## 🔧 Troubleshooting

### "Could not fetch video info"
- Make sure you are **logged into YouTube in Firefox**
- Make sure **Firefox is fully closed** (not just minimised)
- Try updating yt-dlp: run `yt-dlp -U` in the folder

### Downloads failing with 403 error
- Your YouTube session may have expired — log back into YouTube in Firefox
- Make sure Deno is in the same folder as yt-dlp (required for JS challenge solving)
- Update yt-dlp to the latest version

### Thumbnails not embedding
- Make sure **ffmpeg** is installed and accessible
- Check ffmpeg is either in the same folder or on your system PATH
- Run `ffmpeg -version` in a command prompt to verify

### No tracklist generated
- The video may not have chapter markers or timestamps in the description
- Videos without any timing info will simply skip tracklist generation

### "No YouTube URL found in clipboard"
- Make sure you've copied the full URL including `https://`
- The URL must contain `youtube.com` or `youtu.be`

---

## 🧩 How It Works

```
YouTube URL
    │
    ▼
yt-dlp (with Firefox cookies + Deno JS runtime)
    │
    ├─→ Downloads audio/video stream
    ├─→ Saves folder.jpg thumbnail
    └─→ Splits chapters (if selected)
          │
          ▼
        ffmpeg
          │
          ├─→ Converts to MP3
          ├─→ Merges audio + video
          └─→ Embeds folder.jpg as cover art
                │
                ▼
              Python
                │
                ├─→ Renames files (strips duration brackets)
                └─→ Generates tracklist.txt
```

---

## 📦 Dependencies Summary

```
yt-dlp          → Core download engine (update regularly!)
ffmpeg          → Audio/video conversion and thumbnail embedding
deno            → JavaScript runtime for YouTube signature solving
firefox         → Cookie source for YouTube authentication
python 3.9+     → Required for GUI version
PySimpleGUI     → GUI framework (pip install PySimpleGUI==4.60.5)
```

---

## 📝 Notes

- **Keep yt-dlp updated** — YouTube frequently changes its systems and yt-dlp releases fixes regularly. Run `yt-dlp -U` periodically or check [github.com/yt-dlp/yt-dlp/releases](https://github.com/yt-dlp/yt-dldy/releases)
- **Personal use only** — please respect copyright and YouTube's terms of service
- This tool is intended for downloading content you have the right to download (your own uploads, Creative Commons content, or content explicitly permitted for offline use)

- `*VERY* IMPORTANT NOTE!` **Please do *NOT* be tempted to run multiple copies of this tool simultaneously from the SAME installed folder, to batch multi-task / process, at present!** - As the script currently generates `*SET NAMED*` helper *PYTHON* files, `LAST FOLDER` markers, etc, in the installation and/or temp folder, you *WILL* hit problems unless you code in your own changes (or *I* do, when time permits! 😉) to support doing this, or submitting multiple batch URL requests...

---

## 🙏 Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — the brilliant download engine that makes this all possible
- [ffmpeg](https://ffmpeg.org/) — audio/video processing
- [PySimpleGUI](https://github.com/PySimpleGUI/PySimpleGUI) — GUI framework
- [Deno](https://deno.com/) — JavaScript runtime

---

*Built with ❤️ and a lot of Cyberpunk / Synthwave ambient music 🌃*
