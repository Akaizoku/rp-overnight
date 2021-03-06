function Test-DatabaseConnection {
  <#
    .SYNOPSIS
    Test database connection

    .DESCRIPTION
    Check that a database connection is working.

    .PARAMETER DatabaseVendor
    The database vendor parameter corresponds to the type of database.

    .PARAMETER Hostname
    The host name parameter corresponds to the name of the database host.

    .PARAMETER PortNumber
    The port number parameter corresponds to the port number of the database server.

    .PARAMETER Instance
    The instance parameter corresponds to the name of the database instance or service.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of accoun to use in case of SQL authentication.

    .PARAMETER TimeOut
    The optional time-out parameter corresponds to the time in seconds before the connection is deemed unresponsive. The default value is 3 seconds.

    .INPUTS
    None. You cannot pipe objects to Test-DatabaseConnection.

    .OUTPUTS
    Boolean. Test-DatabaseConnection returns a boolean depending on the result of the connection attempt.

    .NOTES
    File name:      Test-DatabaseConnection.ps1
    Author:         Florian Carrier
    Creation date:  20/02/2020
    Last modified:  20/02/2020

    .LINK
    Test-SQLConnection

    .LINK
    Test-OracleConnection

  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Type of the database"
    )]
    [ValidateSet (
      "Oracle",
      "SQLServer"
    )]
    [Alias ("Type")]
    [System.String]
    $DatabaseVendor,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Name of the database host"
    )]
    [ValidateNotNullOrEmpty ()]
    [Alias ("Server")]
    [System.String]
    $Hostname,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "Database server port number"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $PortNumber,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Name of the database instance or service"
    )]
    # [ValidateNotNullOrEmpty ()]
    [Alias ("Service")]
    [System.String]
    $Instance,
    [Parameter (
      Position    = 5,
      Mandatory   = $true,
      HelpMessage = "Name of the database"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $DatabaseName,
    [Parameter (
      Position    = 5,
      Mandatory   = $true,
      HelpMessage = "Database user credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position    = 6,
      Mandatory   = $false,
      HelpMessage = "Connection timeout (in seconds)"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Int32]
    $TimeOut = 3
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Check database type
    switch ($DatabaseVendor) {
      "Oracle" {
        # TODO review database access
        if ($PSBoundParameters.ContainsKey("Credentials")) {
          Test-OracleConnection -Hostname $Hostname -PortNumber $PortNumber -Service $Instance -Credentials $Credentials -TimeOut $TimeOut
        } elseif ($PSBoundParameters.ContainsKey("Username") -And $PSBoundParameters.ContainsKey("Password")) {
          Test-OracleConnection -Hostname $Hostname -PortNumber $PortNumber -Service $Instance -Username $Username -Password $Password -TimeOut $TimeOut
        } else {
          Test-OracleConnection -Hostname $Hostname -PortNumber $PortNumber -Service $Instance -TimeOut $TimeOut
        }
      }
      "SQLServer" {
        if ($PSBoundParameters.ContainsKey("Instance")) {
          $ServerInstance = $Hostname + "\" + $Instance
        } else {
          $ServerInstance = $Hostname
        }
        if ($PSBoundParameters.ContainsKey("Credentials")) {
          Test-SQLConnection -Server $ServerInstance -Database $DatabaseName -Credentials $Credentials -TimeOut $TimeOut
        } elseif ($PSBoundParameters.ContainsKey("Username") -And $PSBoundParameters.ContainsKey("Password")) {
          Test-SQLConnection -Server $ServerInstance -Database $DatabaseName -Username $Username -Password $Password -TimeOut $TimeOut
        } else {
          Test-SQLConnection -Server $ServerInstance -Database $DatabaseName -TimeOut $TimeOut
        }
      }
      default {
        Write-Log -Type "ERROR" -Object "Unsupported database vendor $DatabaseVendor" -ExitCode 1
      }
    }
  }
}
