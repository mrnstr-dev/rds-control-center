if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}
Invoke-ps2exe -InputFile '.\RDSManager.ps1' -OutputFile '.\RDSManager.exe' -IconFile '.\RDSManager.ico' -NoConsole -RequireAdmin -STA -Title 'RDS & FSLogix Control Center' -Company 'IT Administration Tools' -Version '4.0.0.0'
Write-Host 'Build completed: .\RDSManager.exe' -ForegroundColor Green
