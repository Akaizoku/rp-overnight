function Test-RiskPro {
  <#
    .SYNOPSIS
    Check RiskPro

    .DESCRIPTION
    Check the RiskPro application

    .NOTES
    File name:      Test-RiskPro.ps1
    Author:         Florian CARRIER
    Creation date:  20/02/2020
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
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Check application
    Write-Log -Type "INFO" -Object "Checking RiskPro application"
    if ((Test-HTTPStatus -URI $Properties.ServerURI) -eq $false) {
      Write-Log -Type "ERROR" -Object "RiskPro is unreachable ($($Properties.ServerURI))" -ExitCode 1
    }
    # Check credentials
    Write-Log -Type "DEBUG" -Object "Checking user credentials"
    $UnlockUser = Unlock-User -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -UserName $Properties.Credentials.RiskPro.UserName
    if (-Not (Test-RiskProBatchClientOutcome -Log $UnlockUser)) {
      # Check if user is locked
      if (Select-String -InputObject $UnlockUser -Pattern '"User has been locked"' -SimpleMatch -Quiet) {
        Write-Log -Type "ERROR" -Object "RiskPro user ""$($Properties.Credentials.RiskPro.UserName)"" is locked" -ExitCode 1
      } else {
        Write-Log -Type "ERROR" -Object "Invalid credentials for RiskPro user ""$($Properties.Credentials.RiskPro.UserName)""" -ExitCode 1
      }
    }
  }
}
