function Import-MarketData {
  <#
    .SYNOPSIS
    Import market data

    .DESCRIPTION
    Import market data into the reference model

    .NOTES
    File name:      Import-MarketData.ps1
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
    # Merge master model elements
    Write-Log -Type "INFO" -Object "Import master model elements"
    $SolveName = [System.String]::Concat("ImportModelElements", "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
    $ImportModelElements = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ReferenceModelName -SolveName $SolveName -FileName $Properties.PublicMasterModel -ModelElements "MERGE" -SynchronousMode
    Assert-RiskProBatchClientOutcome -Log $ImportModelElements -Object "Master model elements" -Verb "import"
    # Import calendars
    Import-Calendars -Properties $Properties
    # Import observations
    Import-Observations -Properties $Properties
    Write-Log -Type "CHECK" -Object "Reference market data model successfully updated"
  }
}
