@ECHO OFF
REM ===== USER-SET VARIABLES =====
REM You should set this to the (unquoted) path of your perl.exe interpreter. It should work out-of-the-box if you have Strawberry Perl installed to the default directory.
set perl=C:\Strawberry\perl\bin\perl.exe
REM ===== USER-SET VARIABLES =====

REM ===== RESET VARIABLES =====
set sb2=
set sb3=
set zippath=
set supported=
set name=
set projects=0
REM ===== RESET VARIABLES =====

echo Preparing for decompile.
REM we check to see if the files exist so we don't end up doing useless stuff
if exist *.sb2 set sb2=1
if exist *.sb3 set sb3=1

REM check if user has an ID-10T error
if not defined sb2 (
	if not defined sb3 (
		echo Can't find any files to extract, exiting.
		goto END
	)
)
echo Checking for 7-Zip...
REM for testing: goto USEPS
REM Proper 7-Zip install (ex. 64-bit on 64-bit)
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

REM Short for UsePowerShell. I could probably just say UPS but then system admins would think of a giant battery, and normal people would think of a package delivery service.
:USEPS
echo Could not find a 7-Zip install, using PowerShell for zip extraction.
echo You should install 7-Zip. It makes this whole process faster and easier.  That and it can help you with archives in general.
echo Checking for correct version.  This may take a minute.
REM So this is the best way I could find to check if the installed version of PowerShell supports archive commands, basically run the command and detect if it fails
for /f "tokens=* USEBACKQ" %%F in (`powershell "if (Get-Command \"Expand-Archive\" -errorAction SilentlyContinue) {echo 1}"`) do (
	set supported=%%F
)
REM If the command is supported, PowerShell will return 1. If it is not supported, it will return nothing.
if "%supported%" equ "1" (
	echo This version of PowerShell supports archive commands.  Using it.
) else (
	REM If we have no 7-Zip and no recent PowerShell, there's not much we can do.
	echo This version of PowerShell does not support archive commands.  Please either update PowerShell to the latest version or, preferably, install 7-Zip.
	echo This is a fatal error.  The script will now terminate.
	REM As I said at the end of the file, pause before exiting so if the user double-clicked they can read the error instead of just wondering why the window closed.
	pause
	exit /b 1
)

REM TODO: Extract each project in its own directory since this will get confused if there's more than one project here.
if exist *.zip (
	echo Found other .zip file, temporarily renaming to avoid conflicts...
	rename *.zip *.ziptemp
)
echo Changing extension and extracting files.  This may take a minute.
REM PowerShell refuses to extract anything that doesn't have a .zip extension, even if it's a zip file at heart.
REM Extract all files in *.zip to the folder named assets. We'll move project.json out in a minute.
if defined sb2 (
	setlocal ENABLEDELAYEDEXPANSION
	rename *.sb2 *.zip
	for %%f in (*.zip) do (
		REM ~n is filename only, no extension
		set name=%%~nf
		if exist "!name!" (
			echo Folder for !name! already exists, skipping
		) else (
			mkdir "!name!"
			powershell "Expand-Archive -DestinationPath '.\%%~nf\assets\' '%%f'"
			set /a projects=projects+1
		)
	)
	rename *.zip *.sb2
)
if defined sb3 (
	setlocal ENABLEDELAYEDEXPANSION
	rename *.sb3 *.zip
	for %%f in (*.zip) do (
		REM ~n is filename only, no extension
		set name=%%~nf
		if exist "!name!" (
			echo Folder for !name! already exists, skipping
		) else (
			mkdir "!name!"
			powershell "Expand-Archive -DestinationPath '.\%%~nf\assets\' '%%f'"
			set /a projects=projects+1
		)
	)
	rename *.zip *.sb3
)
if exist *.ziptemp (
	echo Putting zip files back...
	rename *.ziptemp *.zip
)
echo Setting date on files...
REM TODO: Set dates on files to same as project?
REM So the reason this is here is that PowerShell refuses to extract dates from Scratch .sb2 files. This results in any extracted files having all interaction dates set as January 1, 1980.
REM Interestingly, when extracted from File Explorer, the resulting dates are in 1601.
REM All this does is set all date attributes of all extracted files to the current date and time.
REM We don't need to with 7-Zip though. Another reason you should get 7-Zip instead of using PowerShell for archive work!
REM I don't know much about PowerShell (I pieced this together from a couple StackExchange answers) so if there's a way to make this better shoot me a pull request!
powershell "Get-ChildItem . | Get-ChildItem | Foreach-Object {$_.lastwritetime=$(Get-Date);$_.lastaccesstime=$(Get-Date);$_.creationtime=$(Get-Date)}"

goto MOVEJSON
REM Short for -- you guessed it -- Use Seven Zip or Use 7-Zip but I try to avoid using digits in labels.
:USESZ
echo Found a 7-Zip executable, using it.
REM extract *.sb2 to folder assets using 7-Zip
REM if defined sb2 %zippath% x -oassets *.sb2
REM if defined sb3 %zippath% x -oassets *.sb3

if defined sb2 (
	setlocal ENABLEDELAYEDEXPANSION
	for %%f in (*.sb2) do (
		REM ~n is filename only, no extension
		set name=%%~nf
		if exist "!name!" (
			echo Folder for !name! already exists, skipping
		) else (
			mkdir "!name!"
			%zippath% x -o"!name!\assets" "%%f"
			set /a projects=projects+1
		)
	)
)
if defined sb3 (
	REM without delayed expansion %name% is empty for some reason?
	setlocal ENABLEDELAYEDEXPANSION
	for %%f in (*.sb3) do (
		set name=%%~nf
		if exist "!name!" (
			echo Folder for !name! already exists, skipping
		) else (
			mkdir "!name!"
			%zippath% x -o"!name!\assets" "%%f"
			set /a projects=projects+1
		)
	)
)
:MOVEJSON
if %projects% equ 0 (
	echo No projects changed, did you forget to delete a project folder to regen?
	goto END
)
echo Moving project.json to root...
for /d %%f in (*) do (
	if "%%f" neq ".git" (
		move "%%f\assets\project.json" "%%f\"
	)
)
if exist "%perl%" (
	echo Perl interpreter found, prettifying project.json
) else (
	echo Could not find Perl interpreter, project.json will not be prettified.
	echo It is recommended to install a Perl interpreter. Since Git seems to track changes by line,
	echo it will not show changes in 'git diff' or commit overview.
	echo If some contributors have Perl and some don't, it will look weird on Git so don't do that. :^)
	goto END
)
for /d %%f in (*) do (
	if exist "%%f\project.json" (
		%perl% prettifyjson.pl "%%f\project.json" > "%%f\prettify-project.json"
		move "%%f\prettify-project.json" "%%f\project.json"
	)
)

:END
echo Done.
REM Always pause at the end of a batch file because otherwise if the user double-clicked on it instead of running it from a command prompt they wouldn't see the final output because the window would just close.
pause
