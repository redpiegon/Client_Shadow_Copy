$AnaDizin=Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$RegPowerRun=$AnaDizin + "\ShadowsCopy.ps1" 
start-process powershell.exe -verb runas -ArgumentList "-ExecutionPolicy Bypass -File $RegPowerRun -Command { Set-ExecutionPolicy Restricted }" -WindowStyle Hidden