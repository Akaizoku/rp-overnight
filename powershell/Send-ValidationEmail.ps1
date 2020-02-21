function Send-ValidationEmail {
  <#
    .SYNOPSIS
    Send validation email

    .DESCRIPTION
    Send validation email message

    .NOTES
    File name:      Send-ValidationEmail.ps1
    Author:         Florian CARRIER
    Creation date:  18/02/2020
    Last modified:  18/02/2020
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
    # Define server instance
    if ($Properties.Database.Result.DatabaseInstance -ne "" -And $Properties.Database.Result.DatabaseInstance -ne $null) {
      $ServerInstance = [System.String]::Concat($Properties.Database.Result.DatabaseHost, "\", $Properties.Database.Result.DatabaseInstance)
    } else {
      $ServerInstance = $Properties.Database.Result.DatabaseHostname
    }
  }
  Process {
    Write-Log -Type "INFO" -Object "Sending validation emails"
    if ($Properties.UseResultDatabase -eq $true) {
      # Define query
      $Query = "EXECUTE [res].[P_Send_Validation_Mail]"
      Write-Log -Type "DEBUG" -Object $Query
      # Export results
      $SQLOutput = Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Properties.Database.Result.DatabaseName -Credential $Properties.Credentials.Result -Query $Query -QueryTimeout $QueryTimeOut -OutputSqlErrors $true -IncludeSqlUserErrors
      # TODO parse results
    } else {
      Write-Log -Type "WARN" -Object "No email configuration was found"
    }
  }
}
