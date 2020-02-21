function Test-Prerequisites {
  <#
    .SYNOPSIS
    Check prerequisites

    .DESCRIPTION
    Check pre-requisites for the overnight process

    .NOTES
    File name:      Test-Prerequisites.ps1
    Author:         Florian CARRIER
    Creation date:  20/02/2020
    Last modified:  20/02/2020
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
    # Check input data
    Test-Inputs -Properties $Properties
    # Check RiskPro platform
    Test-RiskPro -Properties $Properties
    # Check RiskPro models
    Test-Models -Properties $Properties
    # Check databases access
    if ($Properties.UseLogDatabase -eq $true) {
      Write-Log -Type "INFO" -Object "Checking log database connectivity"
      $CheckLogDatabase = Test-DatabaseConnection -DatabaseVendor $Properties.Database.Log.DatabaseType -Hostname $Properties.Database.Log.DatabaseHost -Portnumber $Properties.Database.Log.DatabasePort -Instance $Properties.Database.Log.DatabaseInstance -DatabaseName $Properties.Database.Log.DatabaseName -Credentials $Properties.LogCredentials
      if ($CheckLogDatabase -eq $false) {
        Write-Log -Type "ERROR" -Object "Unable to reach log database $($Properties.Database.Log.DatabaseName)" -ExitCode 1
      }
    }
    if ($Properties.UseResultDatabase -eq $true) {
      $CheckResultDatabase = Test-DatabaseConnection -DatabaseVendor $Properties.Database.Result.DatabaseType -Hostname $Properties.Database.Result.DatabaseHost -Portnumber PropertiesDatabasePort -Instance $Properties.Database.Result.DatabaseInstance -DatabaseName $Properties.Database.Result.DatabaseName -Credentials $Properties.ResultCredentials
      if ($CheckResultDatabase -eq $false) {
        Write-Log -Type "ERROR" -Object "Unable to reach result database $($Properties.Database.Log.DatabaseName)" -ExitCode 1
      }
    }
  }
}
