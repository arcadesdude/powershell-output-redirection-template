# PowerShell Redirection Template example
# Will work with PS V2 and can run through RMM systems
#
# This works when Start-Transcript doesn't work or says it isn't supported by the host
# We're taking the script, putting it into a variable and saving that variable to a file.
#
# Then executing that file and redirecting all output from that file and then getting that file
# and redisplaying it at the end (if needed otherwise there is the log file with all the output)
#
# It does the same as basically: alloutput *> filename.log in the newer versions of PS. The *> redirects
# all output but Version 2 of Powershell doesn't support that. So this is a workaround to avoid having a
# huge upgrade to get everything on newer versions. 
#
# The below works with version 2 and does grab all the
# output into both a logfile and optionally redirects it back to the stdout of the original (this) script
# so any RMM systems can display that output.


# You can initalize inputs from your system here if needed

$content = @'

Write-Output "### Script Start ###"
Write-Output "Start time: $(Get-Date)"
Write-Output "Username: $(([Environment]::UserDomainName + "\" + [Environment]::UserName))"
Write-Output "Hostname: $(& hostname)"
Write-Output "Process ID: $($PID)"
Write-Output "PSVersion: $($PSVersionTable.PSVersion.ToString())"
$a=""
if ($PSVersionTable.PSEdition) {
    $a=$PSVersionTable.PSEdition.ToString()
}
Write-Output "PSEdition: $($a)"
$a=""
($PSVersionTable.PSCompatibleVersions|%{$a+=($_.ToString()+", ")})
$a=$a -Replace(', $','')
Write-Output "PSCompatibleVersions: $($a)"
Write-Output "BuildVersion: $($PSVersionTable.BuildVersion.ToString())"
Write-Output "CLRVersion: $($PSVersionTable.CLRVersion.ToString())"
Write-Output "WSManStackVersion: $($PSVersionTable.WSManStackVersion.ToString())"
Write-Output "PSRemotingProtocolVersion: $($PSVersionTable.PSRemotingProtocolVersion.ToString())"
Write-Output "SerializationVersion: $($PSVersionTable.SerializationVersion.ToString())"
Write-Output "###"

# Rest of script here, it is where the majority of the script goes

'@

# redireciton example

$logdir = "c:\logdir"
$LogPrefix = "log-"
mkdir $logdir -Force | Out-Null
mkdir "c:\logdir\workingdirectory\" -Force | Out-Null

$logDirandPath = $($logdir+$LogPrefix+$(Get-Date -uformat %d-%b-%Y-%H-%M-%S)+".log")


# This is used to pass the logdirandpath variable to the runnerscript so it can access it if needed
$logOptionsContent = @"
if (!`$logDirandPath) { `$logDirandPath = "$logDirandPath" }
"@

# This combines the two herestrings and will be used to set that into a file which will be run in the runnerscript
$content = $logOptionsContent+$content

$runnerscriptname = "$($logdir)\runnerscript.ps1"
Set-Content -Path $runnerscriptname -Value $content -Force

# The 2>&1 redirects error and stdout to stdout and then both get redirected to the log file with the > redirector. 
# I've had issues with AV software when using | Out-File but the > redirector seems to work fine here.
Write-Output "Runner $($runnerscriptname) starting..." | Out-Default
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerscriptname -Verb RunAs 2>&1 > $logDirandPath
Write-Output "Runner finished." | Out-Default

# If you have output variables for the system that is running the PS you can update/output them here to the end.

# If you want to remove the runnerscript when done
if (Test-Path $runnerscriptname) {
    Remove-Item -Confirm:$false $runnerscriptname -Force -Verbose | Out-Default
}
Write-Output "Log file is $($logDirandPath)" | Out-Default

if (Test-Path $logDirandPath) {
    # Write the redirected output back to default console out (includes error streams)
    # This allows the RMM system to pick the output and works with V2 of PS.
    $a = Get-Content $logDirandPath
    Write-Output $a | Out-Default
} else {
    Write-Output "Log file not found." | Out-Default
}



