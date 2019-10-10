@ECHO OFF
set args=
echo Preparing to compile.
:RETURN
if exist *.sb2 goto confirmdel
if exist *.sb3 goto confirmdel
if exist *.zip goto confirmdel
if exist assets goto migrate
echo What level of compression would you like to use?
echo 1) Small size (takes a little while to compress, small file size. Usually negligible benefit)
echo 2) [Recommended] Smaller size (takes slightly longer to compress)
echo 3) Larger size (no compression, potentially slower upload to online editor)
echo Please choose either 1, 2, or 3 and press that key accordingly.
choice /c 123
set compression=%errorlevel%
REM This uses the naming convention difference between Scratch 2 and 3 to detect which one we're working on:
REM Scratch 2 projects use base-10-incrementally-named assets named as 0.*, 1.*, 2.* etc.
REM Scratch 3 projects all use 32-character hexadecimal names.
REM Unless the project is empty, there should be a 0.* and if it's empty why are you compiling it?!
if exist assets/0.* (
	echo Detected Scratch 2 project
	set scratchver=2
) else (
	echo Detected Scratch 3 project
	set scratchver=3
)

echo Checking for 7-Zip...
REM for testing: goto USEPS
REM Proper 7-Zip install (i.e. 64-bit on 64-bit)
if exist "C:\Program Files\7-Zip\7z.exe" set zippath="C:\Program Files\7-Zip\7z.exe"
REM Improper 7-Zip install (32-bit install on 64-bit computer)
if exist "C:\Program Files (x86)\7-Zip\7z.exe" set zippath="C:\Program Files (x86)\7-Zip\7z.exe"
REM Portable 7-Zip executable
if exist "7za.exe" set zippath="7za.exe"
if not defined zippath (
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
REM PowerShell compression has three modes: Optimal, Fastest, and NoCompression. Optimal is default.
if %compression% equ 2 set args=-CompressionLevel Fastest
if %compression% equ 3 set args=-CompressionLevel NoCompression
for /d %%f in (*) do (
	powershell "Compress-Archive -Path '.\%%f\project.json', '.\%%f\assets\*.*' %args% '%%f.zip'"
)
echo Changing file extensions...
REM PowerShell won't even create a zip file with an extension other than .zip so we change it afterwards.
rename *.zip *.sb%scratchver%
goto END
:USESZ
echo Compressing files using Scratch %scratchver%...
REM 7-Zip has several compression modes, usually between 0-9.  9 is most, 0 is none, 5 is default.
if %compression% equ 1 set args=-mx=9
if %compression% equ 3 set args=-mx=0
for /d %%f in (*) do (
	REM Since 7-Zip supports compressing in several different formats, it needs to know the extension it's compressing to.
	%zippath% a %args% "%%f.zip" ".\%%f\assets\*.*" ".\%%f\project.json"
	rename *.zip *.sb%scratchver%
)
goto END
:CONFIRMDEL
REM All caps may not have been necessary but it gets the point across.
echo WARNING! THIS WILL REPLACE ALL .sb2, .sb3, and .zip FILES IN THIS DIRECTORY!  IF YOU DO NOT WANT THEM TO BE OVERWRITTEN PLEASE MOVE THEM BEFORE CONTINUING!
echo Do you accept that continuing will permanently and irreparably overwrite ALL .sb2, .sb3, and .zip files?  If so, please confirm by typing yes.  Otherwise, just press enter.
REM I like little > characters when I'm supposed to type something.
set /p confirm=^>
if "%confirm%" equ "yes" (
	echo Deleting.
	if exist *.sb2 del *.sb2
	if exist *.sb3 del *.sb3
	if exist *.zip del *.zip
	goto return
) else (
	echo Script cannot continue without deleting files, terminating.
	exit /b 1
)
:MIGRATE
echo You seem to be using the old data format. You can auto-m igrate to the new format by letting the script place files in a folder called project. You can rename it later.
echo You can also migrate manually by simply moving the assets folder and project.json into a folder named the same as your project.
echo Migrate automatically? [Y/N]
choice /n
echo %errorlevel%
if "%errorlevel%" equ "1" (
	mkdir project
	move assets project\
	move project.json project\
	echo Migration finished.
	goto RETURN
)
echo Please re-run the script once you have migrated.
exit /b 1
:END
echo All projects compiled.
pause
