function Export-Results {
  <#
    .SYNOPSIS
    Export RiskPro results

    .DESCRIPTION
    Export the results of an anlaysis from RiskPro to a specified external database

    .NOTES
    File name:      Export-Results.ps1
    Author:         Florian CARRIER
    Creation date:  17/02/2020
    Last modified:  21/02/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Database properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $DatabaseProperties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Database user credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Solve name"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $SolveName,
    [Parameter (
      Position    = 4,
      Mandatory   = $true,
      HelpMessage = "Model name"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $ModelName,
    [Parameter (
      Position    = 5,
      Mandatory   = $false,
      HelpMessage = "Query time out (in seconds)"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Int32]
    $QueryTimeOut = 3000
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Define server instance
    if ($DatabaseProperties.DatabaseInstance -ne $null -Or $DatabaseProperties.DatabaseInstance -ne "") {
      $ServerInstance = [System.String]::Concat($DatabaseProperties.DatabaseHost, "\", $DatabaseProperties.DatabaseInstance)
    } else {
      $ServerInstance = $DatabaseProperties.DatabaseHost
    }
    # Sanitize values to prevent issues during insert
    $SanitizedSolveName = $SolveName.Replace("'", "''")
    $SanitizedModelName = $ModelName.Replace("'", "''")
  }
  Process {
    # Define query
    $Query = "EXECUTE [res].[P_Load_Model_Master] '$SanitizedSolveName', '$SanitizedModelName'"
    Write-Log -Type "DEBUG" -Object $Query
    # Export results
    $SQLOutput = Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Database -Credential $Credentials -Query $Query -QueryTimeout $QueryTimeOut -OutputSqlErrors $true -IncludeSqlUserErrors
    # TODO parse results
  }
}
