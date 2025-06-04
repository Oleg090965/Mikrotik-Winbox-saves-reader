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
