function Import-Observations {
  <#
    .SYNOPSIS
    Import observations

    .DESCRIPTION
    Import market data in the reference model

    .NOTES
    File name:      Import-Observations.ps1
    Author:         Florian CARRIER
    Creation date:  17/02/2020
    Last modified:  12/03/2020
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
    # Define market data input path
    $MarketData = Join-Path -Path $Properties.InputDataPath -ChildPath "$($Properties.ProcessingDate)\Market_Data.zip"
  }
  Process {
    Write-Log -Type "INFO" -Object "Importing market data"
    # Check if path exists
    if (Test-Path -Path $MarketData) {
      # Import observations
      Write-Log -Type "DEBUG" -Object "Importing observations $MarketData"
      $SolveName = [System.String]::Concat("ImportObservations_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
      $ImportObservations = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ReferenceModelName -SolveName $SolveName -FileName $MarketData -ModelElements "MERGE" -Observations "UPDATE" -SynchronousMode
      # Check outcome
      Assert-RiskProBatchClientOutcome -Log $ImportObservations -Object $MarketData -Verb "import"
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $MarketData"
      Write-Log -Type "WARN"  -Object "Skipping market data import"
    }
  }
}
