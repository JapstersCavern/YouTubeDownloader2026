@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set KEEPFOLDER=N
set KEEPMAIN=Y

:: --- COLOR SETUP ---

:: This magic line creates a true Escape character for Windows 10/11
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set ESC=%%b

:: Define status variables (using '9' for brighter, more readable colors)
set "SUCCESS=%ESC%[92m[SUCCESS]%ESC%[0m"
set "WARNING=%ESC%[93m[WARNING]%ESC%[0m"
set "ERROR=%ESC%[91m[ERROR]%ESC%[0m"
set "INFO=%ESC%[94m[INFO]%ESC%[0m"
set "CLIPBOARD=%ESC%[92m[FOUND COPIED YOUTUBE VIDEO LINK]%ESC%[0m"

:MAINLOOP
echo.
echo  ==========================================
echo       YT-DLP - Youtube Download Helper!    
echo  ==========================================
echo.

set URL=
set CLIPURL=
for /f "usebackq delims=" %%i in (`powershell -command "Get-Clipboard" 2^>nul`) do set CLIPURL=%%i
set ISYT=N
echo "!CLIPURL!" | findstr /i "youtube.com youtu.be" >nul 2>&1

if "!ERRORLEVEL!"=="0" set ISYT=Y
if "!ISYT!"=="Y" (
    echo.
    echo %CLIPBOARD% :
    echo.
    echo %ESC%[4m!CLIPURL!%ESC%[0m
    echo.
    echo Press Enter to use above, or paste / type a different URL:
    echo.

    set /p URLCHOICE=^> 

    if "!URLCHOICE!"=="" (
        set URL=!CLIPURL!
    ) else (
        set URL=!URLCHOICE!
    )
) else (
    echo.
    set /p URL="Paste a copied URL, and press Enter: "
)

if "!URL!"=="" (
    echo.
    echo %ERROR% : No URL entered. Exiting...
    echo.
    pause
    goto END
)

if "!KEEPFOLDER!"=="Y" (
    echo.
    echo Reusing folder: %ESC%[92m%ESC%[4m!PARENTDIR!%ESC%[0m
    echo.
    goto REUSEFOLDER
)

echo import os > "!TEMP!\ytdl_lastdir.py"
echo f=r'%~dp0lastdir.txt' >> "!TEMP!\ytdl_lastdir.py"
echo print(open(f, encoding='utf-8').read().strip() if os.path.exists(f) else '') >> "!TEMP!\ytdl_lastdir.py"
python "!TEMP!\ytdl_lastdir.py" > "!TEMP!\ytdl_lastdir_val.txt"
for /f "usebackq delims=" %%i in ("!TEMP!\ytdl_lastdir_val.txt") do set LASTDIR=%%i

if "!LASTDIR!"=="" (
    echo.
    echo %INFO% No previously-saved folder info - please enter a target PARENT folder:
    set /p PARENTDIR="Folder: "
    if "!PARENTDIR!"=="" set PARENTDIR=%TEMP%
) else (
    echo.
    echo Last used folder: %ESC%[4m%ESC%[32m!LASTDIR! %ESC%[0m
    echo.
    echo Press Enter to use above, or PASTE / TYPE in a new PARENT folder location:
    echo.

    set /p PARENTDIR=^> 

    if "!PARENTDIR!"=="" set PARENTDIR=!LASTDIR!
    echo !PARENTDIR!> "%~dp0lastdir.txt"
)

:REUSEFOLDER

echo.
echo %INFO% Output folder will be created under: !PARENTDIR!
echo.
echo %INFO% Fetching video information...
echo.

yt-dlp --cookies-from-browser firefox --extractor-args "youtube:player_client=web_embedded" --skip-download --dump-json "!URL!" 2>nul > "!TEMP!\ytdl_meta.json"

echo !PARENTDIR!> "!TEMP!\ytdl_parent.txt"

echo import json, re, os > "!TEMP!\ytdl_helper.py"
echo data=json.loads(open(r'!TEMP!\ytdl_meta.json', encoding='utf-8').read().strip() or '{}') >> "!TEMP!\ytdl_helper.py"
echo parent=open(r'!TEMP!\ytdl_parent.txt', encoding='utf-8').read().strip() >> "!TEMP!\ytdl_helper.py"
echo title=data.get('title','Unknown') >> "!TEMP!\ytdl_helper.py"
echo title=title.encode('ascii','ignore').decode('ascii') >> "!TEMP!\ytdl_helper.py"
echo title=re.sub(r'[\W]', ' ', title) >> "!TEMP!\ytdl_helper.py"
echo title=title.replace('_',' ') >> "!TEMP!\ytdl_helper.py"
echo title=re.sub(r' +', ' ', title).strip() >> "!TEMP!\ytdl_helper.py"
echo if not title or not title.strip(): title=data.get('id','Unknown') >> "!TEMP!\ytdl_helper.py"
echo print(title) >> "!TEMP!\ytdl_helper.py"

echo.
echo %INFO% Retrieving cleaned TITLE name...
echo.

python "!TEMP!\ytdl_helper.py" > "!TEMP!\ytdl_title.txt"
for /f "usebackq delims=" %%i in ("!TEMP!\ytdl_title.txt") do set SUGGESTED=%%i

echo.
echo Suggested folder/file name: %ESC%[4m%ESC%[32m!SUGGESTED! %ESC%[0m
echo.
echo %ESC%[4mPress ENTER to accept SUGGESTED NAME above, or PASTE / TYPE in an alternative folder / location: %ESC%[0m
echo.

set /p FOLDERNAME=^> 

if "!FOLDERNAME!"=="" set FOLDERNAME=!SUGGESTED!

echo !FOLDERNAME!> "!TEMP!\ytdl_foldername.txt"

echo import os > "!TEMP!\ytdl_mkdir.py"
echo parent=open(r'!TEMP!\ytdl_parent.txt', encoding='utf-8').read().strip() >> "!TEMP!\ytdl_mkdir.py"
echo folder=open(r'!TEMP!\ytdl_foldername.txt', encoding='utf-8').read().strip() >> "!TEMP!\ytdl_mkdir.py"
echo path=os.path.join(parent, folder) >> "!TEMP!\ytdl_mkdir.py"
echo os.makedirs(path, exist_ok=True) >> "!TEMP!\ytdl_mkdir.py"
echo print(path) >> "!TEMP!\ytdl_mkdir.py"

echo.
echo %INFO% Running [PYTHON] script to sanitise and create folder name if required...
echo.

python "!TEMP!\ytdl_mkdir.py" > "!TEMP!\ytdl_outdir.txt"
for /f "usebackq delims=" %%i in ("!TEMP!\ytdl_outdir.txt") do set OUTDIR=%%i
if "!OUTDIR!"=="" set OUTDIR=!PARENTDIR!
echo Output folder: !OUTDIR!

CLS

echo.
echo %ESC%[4mWhat would you like to download?%ESC%[0m
echo.
echo.
echo %ESC%[94m    %ESC%[4m1%ESC%[0m. Video (best quality MP4)
echo %ESC%[92m    %ESC%[4m2%ESC%[0m. Audio only (best quality MP3)
echo %ESC%[93m    %ESC%[4m3%ESC%[0m. Video clip (manual start/end time snip)
echo %ESC%[91m    %ESC%[4m4%ESC%[0m. Split video into chapters (separate MP4 per chapter)
echo %ESC%[95m    %ESC%[4m5%ESC%[0m. Split audio into chapters (separate MP3 per chapter)%ESC%[0m
echo.
set /p CHOICE="Enter choice (1-5): %ESC%[95m"

if "!CHOICE!"=="1" goto VIDEO
if "!CHOICE!"=="2" goto MP3
if "!CHOICE!"=="3" goto SNIP
if "!CHOICE!"=="4" goto CHAPTERS_VIDEO
if "!CHOICE!"=="5" goto CHAPTERS_MP3
echo Invalid choice, defaulting to Video...
goto VIDEO

:VIDEO
set DLPATH=!OUTDIR!
CLS
echo.
echo  %ESC%[94m%ESC%[4mDOWNLOADING AS MP4 VIDEO...%ESC%[0m
echo.
yt-dlp --cookies-from-browser firefox -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --extractor-args "youtube:player_client=web_embedded" --embed-thumbnail --merge-output-format mp4 --write-thumbnail --convert-thumbnails jpg --windows-filenames -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
goto FIXTHUMBS

:MP3
set DLPATH=!OUTDIR!
CLS
echo.
echo  %ESC%[92m%ESC%[4mDOWNLOADING AS MP3 AUDIO...%ESC%[0m
echo.
yt-dlp --cookies-from-browser firefox -f "bestaudio/best" --extractor-args "youtube:player_client=web_embedded" --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail --write-thumbnail --convert-thumbnails jpg --windows-filenames -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
goto FIXTHUMBS

:SNIP
set DLPATH=!OUTDIR!
echo.
echo  %ESC%[93m%ESC%[4mDOWNLOADING SNIPPED RANGE as MP4 VIDEO...%ESC%[0m
echo.
echo Enter the start time (eg. 00:01:30 for 1 min 30 sec, or just 00:00:00 for beginning):
set /p TSTART="Start time: "
echo Enter the end time (eg. 00:03:45):
set /p TEND="End time:   "
if "!TSTART!"=="" goto SNIP_ERROR
if "!TEND!"=="" goto SNIP_ERROR
echo.
echo Downloading clip from !TSTART! to !TEND!...
yt-dlp --cookies-from-browser firefox -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --extractor-args "youtube:player_client=web_embedded" --embed-thumbnail --merge-output-format mp4 --download-sections "*!TSTART!-!TEND!" --force-keyframes-at-cuts --write-thumbnail --convert-thumbnails jpg --windows-filenames -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
goto FIXTHUMBS

:SNIP_ERROR
echo.
echo %ERROR% : %ESC%[31m You must enter both a start and end time! %ESC%[0m
echo.
pause
goto DONE

:CHAPTERS_VIDEO
set DLPATH=!OUTDIR!
CLS
echo.
echo  %ESC%[91m%ESC%[4mDOWNLOADING CHAPTERS as MP4 VIDEO...%ESC%[0m
echo.

::set /p KEEPMAIN="Keep the full combined video as well? (Y/N): "
::echo.

::echo Would you like to truncate the download to a specific end time?
::echo (Useful if the video repeats after the tracklist ends)
::set /p TRUNCATE="End time to stop at (eg. 1:20:00), or press Enter to download all: "

SET TRUNCATE=

echo.
echo Splitting video into chapters (separate MP4 per chapter)...
echo.

if "!TRUNCATE!"=="" (
    yt-dlp --cookies-from-browser firefox -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --extractor-args "youtube:player_client=web_embedded" --embed-thumbnail --merge-output-format mp4 --split-chapters --write-thumbnail --convert-thumbnails jpg --windows-filenames -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "chapter:!DLPATH!\%%(section_number)02d - %%(section_title)s.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
) else (
    yt-dlp --cookies-from-browser firefox -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --extractor-args "youtube:player_client=web_embedded" --embed-thumbnail --merge-output-format mp4 --split-chapters --write-thumbnail --convert-thumbnails jpg --windows-filenames --download-sections "*0:00:00-!TRUNCATE!" --force-keyframes-at-cuts -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "chapter:!DLPATH!\%%(section_number)02d - %%(section_title)s.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
)
if /i not "!KEEPMAIN!"=="Y" (
    if exist "!DLPATH!\!FOLDERNAME!.mp4" del "!DLPATH!\!FOLDERNAME!.mp4"
)
echo import os, re > "!TEMP!\ytdl_rename.py"
echo folder=r'!DLPATH!' >> "!TEMP!\ytdl_rename.py"
echo for f in os.listdir(folder): >> "!TEMP!\ytdl_rename.py"
echo     if not f.endswith('.mp4'): continue >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r'\s*[\(\[]\d+[\._:]\d+[\)\]]', '', f).strip() >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r'\s*[\(\[]\s*[\)\]]', '', n).strip() >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r' +', ' ', n).strip() >> "!TEMP!\ytdl_rename.py"
echo     try: os.rename(os.path.join(folder,f), os.path.join(folder,n)) >> "!TEMP!\ytdl_rename.py"
echo     except: pass >> "!TEMP!\ytdl_rename.py"
python "!TEMP!\ytdl_rename.py"
if exist "!TEMP!\ytdl_rename.py" del "!TEMP!\ytdl_rename.py"
goto FIXTHUMBS

:CHAPTERS_MP3
set DLPATH=!OUTDIR!
CLS
echo.
echo  %ESC%[95m%ESC%[4mDOWNLOADING CHAPTERS as MP3 AUDIO...%ESC%[0m
echo.

::set /p KEEPMAIN="Keep the full combined MP3 as well? (Y/N): "
::echo.

::echo Would you like to truncate the download to a specific end time?
::echo (Useful if the video repeats after the tracklist ends)
::set /p TRUNCATE="End time to stop at (eg. 1:20:00), or press Enter to download all: "

SET TRUNCATE=

echo.
echo Splitting audio into chapters (separate MP3 per chapter)...
echo (Thumbnail will be embedded in each MP3 as cover art)
echo.

if "!TRUNCATE!"=="" (
    yt-dlp --cookies-from-browser firefox -f "bestaudio/best" --extractor-args "youtube:player_client=web_embedded" --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail --split-chapters --write-thumbnail --convert-thumbnails jpg --windows-filenames -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "chapter:!DLPATH!\%%(section_number)02d - %%(section_title)s.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
) else (
    yt-dlp --cookies-from-browser firefox -f "bestaudio/best" --extractor-args "youtube:player_client=web_embedded" --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail --split-chapters --write-thumbnail --convert-thumbnails jpg --windows-filenames --download-sections "*0:00:00-!TRUNCATE!" --force-keyframes-at-cuts -o "!DLPATH!\!FOLDERNAME!.%%(ext)s" -o "chapter:!DLPATH!\%%(section_number)02d - %%(section_title)s.%%(ext)s" -o "thumbnail:!DLPATH!\folder" "!URL!"
)

if /i not "!KEEPMAIN!"=="Y" (
    if exist "!DLPATH!\!FOLDERNAME!.mp3" del "!DLPATH!\!FOLDERNAME!.mp3"
)

echo import os, re > "!TEMP!\ytdl_rename.py"
echo folder=r'!DLPATH!' >> "!TEMP!\ytdl_rename.py"
echo for f in os.listdir(folder): >> "!TEMP!\ytdl_rename.py"
echo     if not f.endswith('.mp3'): continue >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r'\s*[\(\[]\d+[\._:]\d+[\)\]]', '', f).strip() >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r'\s*[\(\[]\s*[\)\]]', '', n).strip() >> "!TEMP!\ytdl_rename.py"
echo     n=re.sub(r' +', ' ', n).strip() >> "!TEMP!\ytdl_rename.py"
echo     try: os.rename(os.path.join(folder,f), os.path.join(folder,n)) >> "!TEMP!\ytdl_rename.py"
echo     except: pass >> "!TEMP!\ytdl_rename.py"
python "!TEMP!\ytdl_rename.py"
if exist "!TEMP!\ytdl_rename.py" del "!TEMP!\ytdl_rename.py"
goto FIXTHUMBS

:FIXTHUMBS
set DLPATH=!OUTDIR!
echo.
echo %INFO% %ESC%[4mEmbedding folder.jpg as cover art into MP3s...%ESC%[0m
echo.
echo import os, subprocess > "!TEMP!\ytdl_thumbs.py"
echo folder=r'!DLPATH!' >> "!TEMP!\ytdl_thumbs.py"
echo thumb=os.path.join(folder,'folder.jpg') >> "!TEMP!\ytdl_thumbs.py"
echo if not os.path.exists(thumb): >> "!TEMP!\ytdl_thumbs.py"
echo     print('No folder.jpg found, skipping thumbnail embedding.') >> "!TEMP!\ytdl_thumbs.py"
echo else: >> "!TEMP!\ytdl_thumbs.py"
echo     count=0 >> "!TEMP!\ytdl_thumbs.py"
echo     for f in os.listdir(folder): >> "!TEMP!\ytdl_thumbs.py"
echo         if not f.endswith('.mp3'): continue >> "!TEMP!\ytdl_thumbs.py"
echo         src=os.path.join(folder,f) >> "!TEMP!\ytdl_thumbs.py"
echo         tmp=src+'.tmp.mp3' >> "!TEMP!\ytdl_thumbs.py"
echo         cmd=['ffmpeg','-y','-i',src,'-i',thumb,'-map','0:a','-map','1','-codec','copy','-id3v2_version','3','-metadata:s:v','title=Album cover','-metadata:s:v','comment=Cover (front)',tmp] >> "!TEMP!\ytdl_thumbs.py"
echo         r=subprocess.run(cmd, capture_output=True) >> "!TEMP!\ytdl_thumbs.py"
echo         if r.returncode==0: >> "!TEMP!\ytdl_thumbs.py"
echo             os.replace(tmp, src) >> "!TEMP!\ytdl_thumbs.py"
echo             count+=1 >> "!TEMP!\ytdl_thumbs.py"
echo         else: >> "!TEMP!\ytdl_thumbs.py"
echo             if os.path.exists(tmp): os.remove(tmp) >> "!TEMP!\ytdl_thumbs.py"
echo     print(f'Thumbnails embedded in {count} files.') >> "!TEMP!\ytdl_thumbs.py"
python "!TEMP!\ytdl_thumbs.py"
if exist "!TEMP!\ytdl_thumbs.py" del "!TEMP!\ytdl_thumbs.py"
goto TRACKLIST

:TRACKLIST

echo.
echo %INFO% %ESC%[4mExtracting TRACKLIST (if available)...%ESC%[0m
echo.

set DLPATH=!OUTDIR!
set TFILE=!DLPATH!\tracklist.txt
echo !TFILE!> "!TEMP!\ytdl_tfile.txt"

echo import json, re > "!TEMP!\ytdl_tracklist.py"
echo def clean(s): >> "!TEMP!\ytdl_tracklist.py"
echo     s=s.encode('ascii','ignore').decode('ascii') >> "!TEMP!\ytdl_tracklist.py"
echo     s=re.sub(r'\s*[\(\[]\d+[\.:]\d+[\)\]]', '', s) >> "!TEMP!\ytdl_tracklist.py"
echo     s=re.sub(r'\s*[\(\[]\s*[\)\]]', '', s) >> "!TEMP!\ytdl_tracklist.py"
echo     s=''.join(c if c.isalnum() or c in ' ,.-!?()' else ' ' for c in s) >> "!TEMP!\ytdl_tracklist.py"
echo     s=re.sub(r' +', ' ', s).strip() >> "!TEMP!\ytdl_tracklist.py"
echo     return s >> "!TEMP!\ytdl_tracklist.py"
echo raw=open(r'!TEMP!\ytdl_meta.json', encoding='utf-8').read().strip() >> "!TEMP!\ytdl_tracklist.py"
echo tfile=open(r'!TEMP!\ytdl_tfile.txt', encoding='utf-8').read().strip() >> "!TEMP!\ytdl_tracklist.py"
echo data=json.loads(raw) if raw else {} >> "!TEMP!\ytdl_tracklist.py"
echo chapters=data.get('chapters') >> "!TEMP!\ytdl_tracklist.py"
echo if chapters: >> "!TEMP!\ytdl_tracklist.py"
echo     f=open(tfile, 'w', encoding='utf-8') >> "!TEMP!\ytdl_tracklist.py"
echo     for i,c in enumerate(chapters): >> "!TEMP!\ytdl_tracklist.py"
echo         t=int(c['start_time']) >> "!TEMP!\ytdl_tracklist.py"
echo         h,m,s=t//3600,(t%%3600)//60,t%%60 >> "!TEMP!\ytdl_tracklist.py"
echo         f.write(f'{i+1:02d}. {clean(c["title"])} - {h}:{m:02d}:{s:02d}\n') >> "!TEMP!\ytdl_tracklist.py"
echo     f.close() >> "!TEMP!\ytdl_tracklist.py"
echo     print('Tracklist saved from chapters!') >> "!TEMP!\ytdl_tracklist.py"
echo else: >> "!TEMP!\ytdl_tracklist.py"
echo     desc=data.get('description','') >> "!TEMP!\ytdl_tracklist.py"
echo     pattern=re.compile(r'(?m)^(?:(\d+):)?(\d{1,2}):(\d{2})\s+(.+)$') >> "!TEMP!\ytdl_tracklist.py"
echo     matches=pattern.findall(desc) >> "!TEMP!\ytdl_tracklist.py"
echo     if matches: >> "!TEMP!\ytdl_tracklist.py"
echo         f=open(tfile, 'w', encoding='utf-8') >> "!TEMP!\ytdl_tracklist.py"
echo         for i,(h,m,s,title) in enumerate(matches): >> "!TEMP!\ytdl_tracklist.py"
echo             h=int(h) if h else 0 >> "!TEMP!\ytdl_tracklist.py"
echo             f.write(f'{i+1:02d}. {clean(title)} - {h}:{int(m):02d}:{int(s):02d}\n') >> "!TEMP!\ytdl_tracklist.py"
echo         f.close() >> "!TEMP!\ytdl_tracklist.py"
echo         print('Tracklist saved from description!') >> "!TEMP!\ytdl_tracklist.py"
echo     else: >> "!TEMP!\ytdl_tracklist.py"
echo         print('No chapter or tracklist info found for this video.') >> "!TEMP!\ytdl_tracklist.py"

python "!TEMP!\ytdl_tracklist.py"

echo.
echo %INFO% %ESC%[4mCleaning Temporary Files!...%ESC%[0m
echo.
timeout /t 1 /nobreak >nul
if exist "!TEMP!\ytdl_lastdir.py" del "!TEMP!\ytdl_lastdir.py"
if exist "!TEMP!\ytdl_lastdir_val.txt" del "!TEMP!\ytdl_lastdir_val.txt"
if exist "!TEMP!\ytdl_title.txt" del "!TEMP!\ytdl_title.txt"
if exist "!TEMP!\ytdl_foldername.txt" del "!TEMP!\ytdl_foldername.txt"
if exist "!TEMP!\ytdl_mkdir.py" del "!TEMP!\ytdl_mkdir.py"
if exist "!TEMP!\ytdl_meta.json" del "!TEMP!\ytdl_meta.json"
if exist "!TEMP!\ytdl_outdir.txt" del "!TEMP!\ytdl_outdir.txt"
if exist "!TEMP!\ytdl_parent.txt" del "!TEMP!\ytdl_parent.txt"
if exist "!TEMP!\ytdl_helper.py" del "!TEMP!\ytdl_helper.py"
if exist "!TEMP!\ytdl_tracklist.py" del "!TEMP!\ytdl_tracklist.py"
if exist "!TEMP!\ytdl_tfile.txt" del "!TEMP!\ytdl_tfile.txt"
if exist "!TEMP!\ytdl_delmain.txt" del "!TEMP!\ytdl_delmain.py"

:DONE
echo.
echo Opening output folder...
start "" explorer "!OUTDIR!"

echo.
echo Files saved to: !OUTDIR!
echo.%ESC%[92m
echo =======================================
echo                 Done!
echo =======================================
echo.
echo  %ESC%[4mRun again?%ESC%[0m
echo.
echo     %ESC%[92m%ESC%[4m1%ESC%[0m. Yes, same target folder
echo     %ESC%[93m%ESC%[4m2%ESC%[0m. Yes, choose new folder
echo     %ESC%[91m%ESC%[4m3%ESC%[0m or %ESC%[91m%ESC%[4mRETURN%ESC%[0m. No, exit
echo.

set /p AGAIN="Choice (1-3): "

if "!AGAIN!"=="1" (
    set KEEPFOLDER=Y
    cls
    goto MAINLOOP
)
if "!AGAIN!"=="2" (
    set KEEPFOLDER=N
    cls
    goto MAINLOOP
)

GOTO QUIETEND

:END
echo.
echo Goodbye!
echo.
pause

:QUIETEND
