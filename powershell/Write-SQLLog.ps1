function Write-SQLLog {
  <#
    .SYNOPSIS
    Write log to database

    .DESCRIPTION
    Write script log to dedicated log database

    .NOTES
    File name:      Write-SQLLog.ps1
    Author:         Florian CARRIER
    Creation date:  17/02/2020
    Last modified:  17/02/2020
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
    $DatabaseProperties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "RiskPro automation user credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Log to insert"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Strings]
    $Log,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Source of the log"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $Source = "Automation"
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Define server instance
    if ($DatabaseProperties.LogDatabaseInstance -ne $null -Or $DatabaseProperties.LogDatabaseInstance -ne "") {
      $ServerInstance = [System.String]::Concat($DatabaseProperties.LogDatabaseHost, "\", $DatabaseProperties.LogDatabaseInstance)
    } else {
      $ServerInstance = $DatabaseProperties.LogDatabaseHost
    }
    # Sanitize values to prevent issues during insert
    $SanitizedLog     = $Log.Replace("'", "''")
    $SanitizedSource  = $Source.Replace("'", "''")
  }
  Process {
    # Define query
    $Query = "INSERT INTO b_log (b_log_date, b_log_src, b_log_text) VALUES (GETDATE(), '$SanitizedSource',  '$SanitizedLog')"
    # Write log
    $InsertLog = Invoke-SqlCmd -ServerInstance $ServerInstance -Database $DatabaseProperties.LogDatabaseName -Credentials $Credentials -Query $Query -QueryTimeout 300 -OutputSqlErrors $true -IncludeSqlUserErrors
    # Check eventual errors
  }
}
