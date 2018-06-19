@ECHO OFF
echo Preparing for decompile.
echo Removing old files...
if exist assets\*.* del /Q assets\*.*
if exist project.json del /Q project.json
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
REM Short for UsePowerShell. I could probably just say UPS but then system admins would think of a giant battery, and normal people would think of a package delivery service.  But this way, nobody gets confused.
:USEPS
echo Could not find a 7-Zip install, using PowerShell for zip extraction.
echo You should install 7-Zip. It makes this whole process faster and easier.  That and it can help you with archives in general.
echo Checking for correct version...
REM So this is the best way I could find to check if the installed version of PowerShell supports archive commands.
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
echo Changing file extension...
REM PowerShell refuses to extract anything that doesn't have a .zip extension, even if it's a zip file at heart.
rename *.sb2 *.zip
echo Extracting new files...
REM Extract all files in *.zip to the folder named assets. We'll move project.json out in a minute.
powershell "Expand-Archive -DestinationPath .\assets\ *.zip"
echo Setting date on files...
REM TODO: Set dates on files to same as project?
REM So the reason this is here is that PowerShell refuses to extract dates from Scratch .sb2 files. This results in any extracted files having all interaction dates set as January 1, 1980.
REM Interestingly, when extracted from File Explorer, the resulting dates are in 1601.
REM All this does is set all date attributes of all extracted files to the current date and time.
REM We don't need to with 7-Zip though. Another reason you should get 7-Zip instead of using PowerShell for archive work!
REM I don't know much about PowerShell (I pieced this together from a couple StackExchange answers) so if there's a way to make this better shoot me a pull request!
powershell "Get-ChildItem .\assets\ | Foreach-Object {$_.lastwritetime=$(Get-Date);$_.lastaccesstime=$(Get-Date);$_.creationtime=$(Get-Date)}"
echo Moving project.json to root...
move assets\project.json .
echo Putting file extension back...
rename *.zip *.sb2
goto END
REM Short for -- you guessed it -- Use Seven Zip or Use 7-Zip but I try to avoid using digits in labels.
:USESZ
echo Found a 7-Zip executable, using it.
REM extract *.sb2 to folder assets using 7-Zip
%zippath% x -oassets *.sb2
echo Moving project.json to root...
move assets\project.json .
goto END
:END
echo Success.
REM Always pause at the end of a batch file because otherwise if the user double-clicked on it instead of running it from a command prompt they wouldn't see the final output becuase the window would just close.
pause
