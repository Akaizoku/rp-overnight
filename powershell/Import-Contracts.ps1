function Import-Contracts {
  <#
    .SYNOPSIS
    Import contracts

    .DESCRIPTION
    Import contract data in the production model

    .NOTES
    File name:      Import-Contracts.ps1
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
  }
  Process {
    Write-Log -Type "INFO" -Object "Importing contract data"
    # Define solve properties
    $SolveName  = [System.String]::Concat($Properties.SalginaJobName, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
    $ValidOn    = [System.String]::Concat([Datetime]::ParseExact($Properties.ProcessingDate, "yyyyMMdd", $null).ToString("dd/MM/yyyy"), " ", $Properties.SalginaTimeConvention)
    # Run static solve
    $RunSalgina = Start-GenesisLoader -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -ResultSelection $Properties.SalginaJobName -SolveName $SolveName -LotType $Properties.LotType -ValidOn $ValidOn -SynchronousMode
    Assert-RiskProBatchClientOutcome -Log $RunSalgina -Object "Data foundation loader" -Verb "run" -IrregularForm "run"
  }
}
