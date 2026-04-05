"""
YouTube Downloader 2026
A GUI wrapper for yt-dlp with chapter splitting, thumbnail embedding, and tracklist extraction.
Requires: pip install PySimpleGUI pyinstaller
To build exe: pyinstaller --onefile --windowed --name "YouTubeDownloader2026" YouTubeDownloader2026.py
"""

import PySimpleGUI as sg
import subprocess
import threading
import json
import re
import os
import sys
import glob
import shutil

# ── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(sys.argv[0]))
LASTDIR_FILE = os.path.join(SCRIPT_DIR, "lastdir.txt")
YTDLP = os.path.join(SCRIPT_DIR, "yt-dlp.exe")
FFMPEG = "ffmpeg"  # assumed on PATH or in script dir

# ── Helpers ────────────────────────────────────────────────────────────────

def load_last_dir():
    try:
        if os.path.exists(LASTDIR_FILE):
            return open(LASTDIR_FILE, encoding="utf-8").read().strip()
    except Exception:
        pass
    return ""

def save_last_dir(path):
    try:
        open(LASTDIR_FILE, "w", encoding="utf-8").write(path)
    except Exception:
        pass

def clean_title(title):
    title = title.encode("ascii", "ignore").decode("ascii")
    title = re.sub(r"[\W]", " ", title)
    title = title.replace("_", " ")
    title = re.sub(r" +", " ", title).strip()
    return title

def clean_track(s):
    s = s.encode("ascii", "ignore").decode("ascii")
    s = re.sub(r"\s*[\(\[]\d+[\.:]\d+[\)\]]", "", s)
    s = re.sub(r"\s*[\(\[]\s*[\)\]]", "", s)
    s = "".join(c if c.isalnum() or c in " ,.-!?()" else " " for c in s)
    s = re.sub(r" +", " ", s).strip()
    return s

def get_video_info(url, log):
    log("Fetching video info...")
    try:
        result = subprocess.run(
            [YTDLP, "--cookies-from-browser", "firefox",
             "--extractor-args", "youtube:player_client=web_embedded",
             "--skip-download", "--dump-json", url],
            capture_output=True, text=True, encoding="utf-8", errors="ignore"
        )
        if result.returncode != 0 or not result.stdout.strip():
            log("⚠ Could not fetch video info.")
            return None
        return json.loads(result.stdout.strip())
    except Exception as e:
        log(f"⚠ Error fetching info: {e}")
        return None

def get_suggested_name(data):
    if not data:
        return "Unknown"
    title = data.get("title", "Unknown")
    cleaned = clean_title(title)
    return cleaned if cleaned.strip() else data.get("id", "Unknown")

def make_output_dir(parent, folder):
    path = os.path.join(parent, folder)
    os.makedirs(path, exist_ok=True)
    return path

def build_ytdlp_cmd(mode, url, dlpath, foldername, tstart=None, tend=None, truncate=None):
    base = [YTDLP,
            "--cookies-from-browser", "firefox",
            "--extractor-args", "youtube:player_client=web_embedded",
            "--write-thumbnail", "--convert-thumbnails", "jpg",
            "--windows-filenames",
            "-o", f"thumbnail:{dlpath}\\folder"]

    if mode == "video":
        return base + [
            "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
            "--embed-thumbnail", "--merge-output-format", "mp4",
            "-o", f"{dlpath}\\{foldername}.%(ext)s",
            url]

    elif mode == "mp3":
        return base + [
            "-f", "bestaudio/best",
            "--extract-audio", "--audio-format", "mp3", "--audio-quality", "0",
            "--embed-thumbnail",
            "-o", f"{dlpath}\\{foldername}.%(ext)s",
            url]

    elif mode == "snip":
        return base + [
            "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
            "--embed-thumbnail", "--merge-output-format", "mp4",
            "--download-sections", f"*{tstart}-{tend}",
            "--force-keyframes-at-cuts",
            "-o", f"{dlpath}\\{foldername}.%(ext)s",
            url]

    elif mode == "chapters_video":
        cmd = base + [
            "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
            "--embed-thumbnail", "--merge-output-format", "mp4",
            "--split-chapters",
            "-o", f"{dlpath}\\{foldername}.%(ext)s",
            "-o", f"chapter:{dlpath}\\%(section_number)02d - %(section_title)s.%(ext)s"]
        if truncate:
            cmd += ["--download-sections", f"*0:00:00-{truncate}", "--force-keyframes-at-cuts"]
        return cmd + [url]

    elif mode == "chapters_mp3":
        cmd = base + [
            "-f", "bestaudio/best",
            "--extract-audio", "--audio-format", "mp3", "--audio-quality", "0",
            "--embed-thumbnail", "--split-chapters",
            "-o", f"{dlpath}\\{foldername}.%(ext)s",
            "-o", f"chapter:{dlpath}\\%(section_number)02d - %(section_title)s.%(ext)s"]
        if truncate:
            cmd += ["--download-sections", f"*0:00:00-{truncate}", "--force-keyframes-at-cuts"]
        return cmd + [url]

    return []

def rename_files(folder, ext, log):
    count = 0
    for f in os.listdir(folder):
        if not f.endswith(ext):
            continue
        n = re.sub(r"\s*[\(\[]\d+[\._:]\d+[\)\]]", "", f).strip()
        n = re.sub(r"\s*[\(\[]\s*[\)\]]", "", n).strip()
        n = re.sub(r" +", " ", n).strip()
        if n != f:
            try:
                os.rename(os.path.join(folder, f), os.path.join(folder, n))
                count += 1
            except Exception:
                pass
    if count:
        log(f"✓ Renamed {count} files (brackets stripped)")

def embed_thumbnails(folder, log):
    thumb = os.path.join(folder, "folder.jpg")
    if not os.path.exists(thumb):
        log("⚠ No folder.jpg found, skipping thumbnail embedding.")
        return
    count = 0
    for f in os.listdir(folder):
        if not f.endswith(".mp3"):
            continue
        src = os.path.join(folder, f)
        tmp = src + ".tmp.mp3"
        cmd = [FFMPEG, "-y", "-i", src, "-i", thumb,
               "-map", "0:a", "-map", "1", "-codec", "copy",
               "-id3v2_version", "3",
               "-metadata:s:v", "title=Album cover",
               "-metadata:s:v", "comment=Cover (front)", tmp]
        r = subprocess.run(cmd, capture_output=True)
        if r.returncode == 0:
            os.replace(tmp, src)
            count += 1
        else:
            if os.path.exists(tmp):
                os.remove(tmp)
    log(f"✓ Thumbnails embedded in {count} MP3 files")

def extract_tracklist(data, outdir, log):
    tfile = os.path.join(outdir, "tracklist.txt")
    chapters = data.get("chapters") if data else None

    if chapters:
        lines = []
        for i, c in enumerate(chapters):
            t = int(c["start_time"])
            h, m, s = t // 3600, (t % 3600) // 60, t % 60
            lines.append(f"{i+1:02d}. {clean_track(c['title'])} - {h}:{m:02d}:{s:02d}")
        open(tfile, "w", encoding="utf-8").write("\n".join(lines) + "\n")
        log(f"✓ Tracklist saved from chapters ({len(lines)} tracks)")
        return

    desc = data.get("description", "") if data else ""
    pattern = re.compile(r"(?m)^(?:(\d+):)?(\d{1,2}):(\d{2})\s+(.+)$")
    matches = pattern.findall(desc)
    if matches:
        lines = []
        for i, (h, m, s, title) in enumerate(matches):
            h = int(h) if h else 0
            lines.append(f"{i+1:02d}. {clean_track(title)} - {h}:{int(m):02d}:{int(s):02d}")
        open(tfile, "w", encoding="utf-8").write("\n".join(lines) + "\n")
        log(f"✓ Tracklist saved from description ({len(lines)} tracks)")
    else:
        log("ℹ No chapter or tracklist info found for this video")

def run_download(values, window, data):
    def log(msg):
        window.write_event_value("-LOG-", msg)

    try:
        url = values["-URL-"]
        parent = values["-PARENT-"]
        foldername = values["-FOLDERNAME-"]
        mode = values["-MODE-"]
        tstart = values.get("-TSTART-", "")
        tend = values.get("-TEND-", "")
        truncate = values.get("-TRUNCATE-", "")
        keep_main = values.get("-KEEPMAIN-", True)

        if not url or not parent or not foldername:
            log("⚠ Missing URL, folder, or name!")
            window.write_event_value("-DONE-", False)
            return

        save_last_dir(parent)
        dlpath = make_output_dir(parent, foldername)
        log(f"✓ Output folder: {dlpath}")

        # Map radio button to mode string
        mode_map = {
            "Video (MP4)": "video",
            "Audio (MP3)": "mp3",
            "Clip / Snip (MP4)": "snip",
            "Split chapters (MP4)": "chapters_video",
            "Split chapters (MP3)": "chapters_mp3",
        }
        mode_key = mode_map.get(mode, "mp3")

        cmd = build_ytdlp_cmd(
            mode_key, url, dlpath, foldername,
            tstart=tstart, tend=tend,
            truncate=truncate if truncate else None
        )

        log(f"▶ Starting download ({mode})...")
        proc = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, encoding="utf-8", errors="ignore"
        )
        for line in proc.stdout:
            line = line.rstrip()
            if line:
                log(line)
        proc.wait()

        if proc.returncode != 0:
            log("⚠ yt-dlp reported an error — check output above")
        else:
            log("✓ Download complete!")

        # Post-processing
        if mode_key in ("chapters_video", "chapters_mp3"):
            ext = ".mp4" if mode_key == "chapters_video" else ".mp3"
            rename_files(dlpath, ext, log)
            if not keep_main:
                main_file = os.path.join(dlpath, foldername + ext)
                if os.path.exists(main_file):
                    os.remove(main_file)
                    log(f"✓ Removed combined file")

        if mode_key in ("mp3", "chapters_mp3", "snip"):
            embed_thumbnails(dlpath, log)

        extract_tracklist(data, dlpath, log)

        log("✓ All done!")
        window.write_event_value("-DONE-", dlpath)

    except Exception as e:
        log(f"⚠ Error: {e}")
        window.write_event_value("-DONE-", False)

# ── GUI ────────────────────────────────────────────────────────────────────

def get_clipboard_url():
    try:
        import tkinter as tk
        root = tk.Tk()
        root.withdraw()
        clip = root.clipboard_get()
        root.destroy()
        if "youtube.com" in clip or "youtu.be" in clip:
            return clip.strip()
    except Exception:
        pass
    return ""

def make_layout(last_dir, clip_url):
    sg.theme("DarkGrey13")

    ACCENT = "#5865F2"
    BTN = {"button_color": (ACCENT, "#2B2D31"), "border_width": 0}

    modes = ["Audio (MP3)", "Video (MP4)", "Split chapters (MP3)",
             "Split chapters (MP4)", "Clip / Snip (MP4)"]

    url_default = clip_url if clip_url else ""
    url_hint = "YouTube URL detected in clipboard!" if clip_url else "Paste YouTube URL here..."

    layout = [
        [sg.Text("🎵 YouTube Downloader 2026", font=("Segoe UI", 16, "bold"),
                 text_color=ACCENT, background_color="#1E1F22")],
        [sg.HSeparator()],

# URL
        [sg.Text("URL", size=(12, 1), font=("Segoe UI", 10, "bold")),
         sg.Input(url_default, key="-URL-", size=(45, 1), enable_events=True,
                  tooltip=url_hint, font=("Segoe UI", 10)),
         sg.Button("📋 Paste URL", key="-CLIPBOARD-", button_color=(ACCENT, "#2B2D31"),
                   border_width=0, font=("Segoe UI", 10))],

        # Parent folder
        [sg.Text("Output folder", size=(12, 1), font=("Segoe UI", 10, "bold")),
         sg.Input(last_dir, key="-PARENT-", size=(45, 1), font=("Segoe UI", 10)),
         sg.FolderBrowse("Browse", button_color=(ACCENT, "#2B2D31"))],

        [sg.HSeparator()],

        # Fetch info button
        [sg.Button("🔍 Fetch Video Info", key="-FETCH-", **BTN, font=("Segoe UI", 10)),
         sg.Text("", key="-TITLESHOW-", font=("Segoe UI", 10, "italic"),
                 text_color="#57F287", size=(50, 1))],

        # Folder/file name
        [sg.Text("Folder / File name", size=(12, 1), font=("Segoe UI", 10, "bold")),
         sg.Input("", key="-FOLDERNAME-", size=(55, 1), font=("Segoe UI", 10))],

        [sg.HSeparator()],

        # Download mode
        [sg.Text("Download mode", font=("Segoe UI", 10, "bold"))],
        [sg.Column([[sg.Radio(m, "MODE", key=f"-MODE-{m}-",
                              default=(m == "Audio (MP3)"),
                              enable_events=True,
                              font=("Segoe UI", 10))] for m in modes])],

        # Snip times (shown only for snip mode)
        [sg.pin(sg.Column([
            [sg.Text("Start time", size=(10, 1)), sg.Input("00:00:00", key="-TSTART-", size=(12, 1)),
             sg.Text("End time", size=(8, 1)), sg.Input("", key="-TEND-", size=(12, 1))]
        ], key="-SNIP_ROW-", visible=False))],

        # Truncate (shown for chapter modes)
        [sg.pin(sg.Column([
            [sg.Text("Truncate at", size=(10, 1)),
             sg.Input("", key="-TRUNCATE-", size=(12, 1),
                      tooltip="Leave blank to download all. Enter time eg. 1:20:00 to stop early."),
             sg.Text("(leave blank for full download)", font=("Segoe UI", 9, "italic"))]
        ], key="-TRUNC_ROW-", visible=False))],

        # Keep main file
        [sg.Checkbox("Keep combined file when splitting chapters",
                     key="-KEEPMAIN-", default=True, font=("Segoe UI", 10))],

        [sg.HSeparator()],

        # Download button
        [sg.VPush()],
        [sg.Button("⬇  Download", key="-DOWNLOAD-", font=("Segoe UI", 11, "bold"),
                   button_color=("#FFFFFF", "#2563EB"), border_width=0, size=(16, 1),
                   disabled=True),
         sg.Button("📂 Open Folder", key="-OPENFOLDER-",
                   button_color=("#FFFFFF", "#3D3F45"), border_width=0,
                   font=("Segoe UI", 10), disabled=True)],

        # Progress bar
        [sg.ProgressBar(100, orientation="h", size=(60, 12),
                        key="-PROG-", bar_color=("#57F287", "#111214"))],

        # Log output
        [sg.Multiline("", key="-LOG-", size=(75, 14), disabled=True,
                      autoscroll=True, font=("Consolas", 9),
                      background_color="#111214", text_color="#DCDDDE",
                      no_scrollbar=False)],
    ]

    return [[sg.Column(layout, background_color="#1E1F22",
                       element_justification="left",
                       expand_x=True, expand_y=True,
                       pad=(16, 16))]]

def main():
    last_dir = load_last_dir()
    clip_url = get_clipboard_url()

    layout = make_layout(last_dir, clip_url)
    window = sg.Window(
        "YouTube Downloader 2026",
        layout,
        finalize=True,
        resizable=True,
        background_color="#1E1F22",
        icon=None,
        size=(820, 700)
    )

    if clip_url:
        window["-LOG-"].update(f"📋 YouTube URL detected in clipboard:\n{clip_url}\n")

    data = None
    last_outdir = None
    downloading = False
    prog_val = 0

    CHAPTER_MODES = {"Split chapters (MP3)", "Split chapters (MP4)"}
    SNIP_MODE = "Clip / Snip (MP4)"

    def current_mode():
        modes = ["Audio (MP3)", "Video (MP4)", "Split chapters (MP3)",
                 "Split chapters (MP4)", "Clip / Snip (MP4)"]
        for m in modes:
            if window[f"-MODE-{m}-"].get():
                return m
        return "Audio (MP3)"

    while True:
        event, values = window.read(timeout=100)

        if event in (sg.WIN_CLOSED, "Exit"):
            break

        # Mode radio changed — show/hide rows
        mode = current_mode()
        window["-SNIP_ROW-"].update(visible=(mode == SNIP_MODE))
        window["-TRUNC_ROW-"].update(visible=(mode in CHAPTER_MODES))

        # Fake progress animation while downloading
        if downloading:
            prog_val = (prog_val + 1) % 100
            window["-PROG-"].update(prog_val)

        if event == "-FETCH-":
            url = values["-URL-"].strip()
            if not url:
                sg.popup_error("Please enter a YouTube URL first!", title="No URL")
                continue
            window["-LOG-"].update("")
            window["-TITLESHOW-"].update("Fetching...")
            window.refresh()

            def fetch_thread():
                nonlocal data
                data = get_video_info(url, lambda m: window.write_event_value("-LOG-", m))
                suggested = get_suggested_name(data)
                window.write_event_value("-FETCHED-", suggested)

            threading.Thread(target=fetch_thread, daemon=True).start()

        elif event == "-FETCHED-":
            suggested = values[event]
            window["-FOLDERNAME-"].update(suggested)
            window["-TITLESHOW-"].update(f"✓  {suggested}")
            window["-DOWNLOAD-"].update(disabled=False)

        elif event == "-URL-":
            data = None
            window["-DOWNLOAD-"].update(disabled=True)
            window["-TITLESHOW-"].update("")

        elif event == "-CLIPBOARD-":
            clip = get_clipboard_url()
            if clip:
                window["-URL-"].update(clip)
                data = None
                window["-DOWNLOAD-"].update(disabled=True)
                window["-TITLESHOW-"].update("")
                window["-LOG-"].update(f"📋 URL pasted from clipboard:\n{clip}\n")
            else:
                sg.popup_error("No YouTube URL found in clipboard!",
                               title="Nothing to paste")

        elif event == "-DOWNLOAD-":
            if downloading:
                continue
            url = values["-URL-"].strip()
            parent = values["-PARENT-"].strip()
            foldername = values["-FOLDERNAME-"].strip()
            if not url:
                sg.popup_error("Please enter a URL!", title="Missing URL")
                continue
            if not parent:
                sg.popup_error("Please choose an output folder!", title="Missing Folder")
                continue
            if not foldername:
                sg.popup_error("Please fetch video info or enter a folder name!",
                               title="Missing Name")
                continue

            if not data:
                sg.popup_error(
                    "Please fetch video info first!\n\nClick '🔍 Fetch Video Info' before downloading.",
                    title="Info not fetched"
                )
                continue

            # Build values dict with mode
            dl_values = dict(values)
            dl_values["-MODE-"] = current_mode()

            window["-LOG-"].update("")
            window["-DOWNLOAD-"].update(disabled=True)
            window["-OPENFOLDER-"].update(disabled=True)
            downloading = True
            prog_val = 0

            threading.Thread(
                target=run_download,
                args=(dl_values, window, data),
                daemon=True
            ).start()

        elif event == "-LOG-":
            current = window["-LOG-"].get()
            window["-LOG-"].update(current + values[event] + "\n")

        elif event == "-DONE-":
            downloading = False
            window["-PROG-"].update(100)
            window["-DOWNLOAD-"].update(disabled=False)
            result = values[event]
            if result:
                last_outdir = result
                window["-OPENFOLDER-"].update(disabled=False)
                sg.popup_quick_message("✓  Download complete!", auto_close_duration=2,
                                       background_color="#57F287", text_color="#000000")
            else:
                sg.popup_error("Download failed — check the log for details.",
                               title="Error")

        elif event == "-OPENFOLDER-":
            if last_outdir and os.path.exists(last_outdir):
                os.startfile(last_outdir)

    window.close()

if __name__ == "__main__":
    main()
