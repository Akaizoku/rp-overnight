function Start-CleanUp {
  <#
    .SYNOPSIS
    Clean-up

    .DESCRIPTION
    Clean-up temporary files

    .NOTES
    File name:      Start-CleanUp.ps1
    Author:         Florian CARRIER
    Creation date:  21/02/2020
    Last modified:  21/02/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Script properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Temporary files firectory"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $TmpDirectory,
    [Parameter (
      HelpMessage = "Run script in unattended mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Clean-up temporary directory
    if (Test-Path -Path $TmpDirectory) {
      Write-Log -Type "DEBUG" -Object "Removing temporary directory"
      Write-Log -Type "DEBUG" -Object $TmpDirectory
      Remove-Item -Path $TmpDirectory -Recurse -Force -Confirm:$Properties.Attended
    }
  }
}
