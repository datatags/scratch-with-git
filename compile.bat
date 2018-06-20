@ECHO OFF
echo Preparing to compile.
if exist project.sb2 goto confirmdel
if exist project.zip goto confirmdel
:RETURN
echo Would you like to compile for the online or offline editor?
echo 1) Offline editor (smaller file size, but takes an indeterminately long time to upload to the online editor.)
echo 2) Online  editor (larger file size, works in both the online and offline editors.) [Default]
echo Please choose either 1 or 2 and press that key accordingly.
choice /c 12
set compression=%errorlevel%
echo Checking for 7-Zip...
REM for testing: goto USEPS
set zippath=null
REM Proper 7-Zip install (i.e. 64-bit on 64-bit)
if exist "C:\Program Files\7-Zip\7z.exe" set zippath="C:\Program Files\7-Zip\7z.exe"
REM Improper 7-Zip install (32-bit install on 64-bit computer)
if exist "C:\Program Files (x86)\7-Zip\7z.exe" set zippath="C:\Program Files (x86)\7-Zip\7z.exe"
REM Portable 7-Zip executable
if exist "7za.exe" set zippath="7za.exe"
if %zippath% equ null (
	goto useps
) else (
	goto usesz
)
:USEPS
echo Could not find a 7-Zip executable, using PowerShell for zip extraction.
echo You should install 7-Zip. It makes this whole process faster and easier.  That and it can help you with archives in general.
echo Checking for correct version...
REM See decompile.bat for my notes on this part.
for /f "tokens=* USEBACKQ" %%F in (`powershell "if (Get-Command \"Compress-Archive\" -errorAction SilentlyContinue) {echo 1}"`) do (
	set supported=%%F
)
if "%supported%" equ "1" (
	echo This version of PowerShell supports archive commands.  Using it.
) else (
	echo This version of PowerShell does not support archive commands.  Please either update PowerShell to the latest version or, preferably, install 7-Zip.
	echo This is a fatal error.  The script will now terminate.
	pause
	exit /b 1
)
echo Compressing files...
REM Compress project.json and all files in the assets folder into a zip file named project.zip
REM PowerShell by default compresses the files in a zip more, but the offline editor seems to still be able to read it.  On a ~30MB project it reduced the size to ~24MB after decompiling and recompiling.
if %compression% equ 2 set args=-CompressionLevel NoCompression
powershell "Compress-Archive -Path .\project.json, .\assets\*.* %args% project.zip"
echo Changing file extension...
REM PowerShell won't even create a zip file with an extension other than .zip so we change it afterwards.
rename project.zip project.sb2
goto END
:USESZ
echo Compressing files...
if %compression% equ 2 set args=-mx=0
REM Since 7-Zip supports compressing in several different formats, it needs to know the extension it's compressing to.
%zippath% a %args% project.zip assets\*.* project.json
echo Changing file extension...
rename project.zip project.sb2
goto END
:CONFIRMDEL
REM All caps may not have been necessary but it gets the point across.
echo WARNING! THIS WILL OVERWRITE project.sb2 AND project.zip!  IF YOU DO NOT WANT THEM TO BE OVERWRITTEN PLEASE RENAME THEM BEFORE CONTINUING!
echo Do you accept that continuing will permanently and irreparably overwrite project.sb2 and project.zip?  If so, please confirm by typing yes.  Otherwise, just press enter.
REM I like little > characters when I'm supposed to type something.
set /p confirm=^>
if "%confirm%" equ "yes" (
	echo Deleting.
	if exist project.sb2 del project.sb2
	if exist project.zip del project.zip
	goto return
) else (
	echo Terminating.
	exit /b 1
)

:END
echo Project successfully compiled.
pause
