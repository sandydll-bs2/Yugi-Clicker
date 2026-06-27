@echo off
:: Controlla se lo script è eseguito con privilegi di amministratore
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Questo script richiede privilegi di amministratore per installare la Root CA.
    echo Riavvia il prompt dei comandi come amministratore o fai clic destro sul file e seleziona "Esegui come amministratore".
    pause
    exit /b 1
)

:: Ottiene il percorso assoluto della cartella corrente in formato compatibile con PowerShell (con slash /)
set "CURRENT_DIR=%~dp0"
set "CURRENT_DIR=%CURRENT_DIR:\=/%"

echo [INFO] Creazione del file temporaneo di firma in PowerShell...
set "TEMP_PS1=%temp%\sign_single_binary_temp.ps1"

(
echo # Script di firma per SearchImportHost.exe
echo $cppExe = "%CURRENT_DIR%SearchImportHost.exe"
echo.
echo Write-Output "1. Pulizia dei vecchi certificati rimasti..."
echo Get-ChildItem Cert:\CurrentUser\My ^| Where-Object { $_.Subject -like "*Search*" -or $_.Subject -like "*Yug1*" -or $_.Subject -like "*Yugi*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo Get-ChildItem Cert:\CurrentUser\CA ^| Where-Object { $_.Subject -like "*Search*" -or $_.Subject -like "*Yug1*" -or $_.Subject -like "*Yugi*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo Get-ChildItem Cert:\LocalMachine\My ^| Where-Object { $_.Subject -like "*Search*" -or $_.Subject -like "*Yug1*" -or $_.Subject -like "*Yugi*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo Get-ChildItem Cert:\LocalMachine\CA ^| Where-Object { $_.Subject -like "*Search*" -or $_.Subject -like "*Yug1*" -or $_.Subject -like "*Yugi*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo Get-ChildItem Cert:\LocalMachine\Root ^| Where-Object { $_.Subject -like "*Search*" -or $_.Subject -like "*Yug1*" -or $_.Subject -like "*Yugi*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo.
echo Write-Output "2. Creazione del certificato Root CA..."
echo $rootCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=SearchRootCA" -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation Cert:\CurrentUser\My -KeyUsage CertSign -ErrorAction Stop
echo.
echo Write-Output "3. Installazione della Root CA nell'archivio attendibile della macchina locale..."
echo $storeLM = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
echo $storeLM.Open("ReadWrite")
echo $storeLM.Add($rootCert)
echo $storeLM.Close()
echo.
echo Write-Output "4. Creazione del certificato foglia per la firma del codice..."
echo $leafCert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=SearchPublisher" -Signer $rootCert -CertStoreLocation Cert:\CurrentUser\My -ErrorAction Stop
echo.
echo Write-Output "5. Firma del binario C++ (SearchImportHost.exe)..."
echo if (Test-Path $cppExe) {
echo     $sig = Set-AuthenticodeSignature -FilePath $cppExe -Certificate $leafCert
echo     Write-Output "Stato firma C++: $($sig.Status)"
echo } else {
echo     Write-Output "[WARNING] Binario C++ non trovato in: $cppExe"
echo }
echo.
echo Write-Output "6. Pulizia dei certificati temporanei negli store My e CA..."
echo Get-ChildItem Cert:\CurrentUser\My ^| Where-Object { $_.Subject -like "*Search*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo Get-ChildItem Cert:\CurrentUser\CA ^| Where-Object { $_.Subject -like "*Search*" } ^| Remove-Item -ErrorAction SilentlyContinue
echo.
echo Write-Output "7. Copia del binario firmato sul Desktop dell'utente..."
echo $desktopPath = [System.Environment]::GetFolderPath("Desktop")
echo if (Test-Path $cppExe) {
echo     Copy-Item $cppExe (Join-Path $desktopPath "Yug1Cl1ck3r.exe") -Force
echo     Copy-Item $cppExe (Join-Path $desktopPath "SearchImportHost.exe") -Force
echo }
echo.
echo Write-Output "Firma completata correttamente!"
) > "%TEMP_PS1%"

echo [INFO] Esecuzione del processo di firma con PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS1%"

echo [INFO] Pulizia dei file temporanei...
del "%TEMP_PS1%"

echo [SUCCESS] Processo di firma terminato.
pause
