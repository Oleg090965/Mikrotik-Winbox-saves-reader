 Powershell script.
 
 Get-WinBoxSaves.ps1
 
 For those who "forget" logins. Reads the winbox save database.
 
 Outputs logins and passwords from an unencrypted database.

 Usage 
 
 .\Get-WinboxSaves.ps1  [-Help] [-Dialog] [-Path] [-Console] [-HTML] [-HTMLPath]
-    -Help     - Show help.
-    -Dialog   - Only for OS MS Windows. Open "File open dialog" window. 
-    -Path     - Full path to Winbox save file (usually "Addresses.cdb").
-    -Console  - Only for OS MS Windows. Output to console. Don't open result window.
-    -HTML     - Write output result to html file and open brouser.
-    -HTMLPath - Full path to .html file. If missin

When launched without parameters in:
1)  OS MS Windows - it attempts to open the file %APPDATA%\MikroTik\WinBox\Addresses.cdb (if the file is missing, it displays a "File Open Dialog"). The results are shown in a pop-up window.
2)  OS Linux - it displays help information.
