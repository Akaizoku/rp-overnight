function Start-AutomationMaintenance {
  <#
    .SYNOPSIS
    Start maintenance

    .DESCRIPTION
    Launch automation maintenance process

    .NOTES
    File name:      Start-AutomationMaintenance.ps1
    Author:         Florian CARRIER
    Creation date:  18/02/2020
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
    # List solves
    $CleanRollUpSolves = $Properties.Solves | Where-Object -Property "Solve kind" -CEQ -Value "CleanRollup" | Select-Object -ExpandProperty "Solve name"
  }
  Process {
    Write-Log -Type "INFO" -Object "Starting automation maintenance process"
    # Purge
    if ($CleanRollUpSolves -ge 1) {
      foreach ($CleanRollUpSolve in $CleanRollUpSolves) {
        Write-Log -Type "INFO" -Object "Starting clean-roll-up solve ""$CleanRollUpSolve"""
        # Define solve properties
        $SolveProperties  = $Properties.Solves | Where-Object -Property "Solve name" -CEQ -Value $CleanRollUpSolve
        $SolveName        = [System.String]::Concat($CleanRollUpSolve, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $BeginDate        = [System.String]::Concat($Properties.AnalysisDate, " AM")
        $EndDate          = [System.String]::Concat($Properties.AnalysisDate, " PM")
        # Run clean-roll-up solve
        $RunRollUpSolve = Start-CleanRollupSolve -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.HistorisationModelName -ResultSelection $CleanRollUpSolve -SolveName $SolveName -BeginDate $BeginDate -EndDate $EndDate -SynchronousMode
        Assert-RiskProBatchClientOutcome -Log $RunRollUpSolve -Object "Clean-roll-up solve ""$CleanRollUpSolve""" -Verb "run" -IrregularForm "run"
        # Save results
        if ($Properties.UseResultDatabase -eq $true) {
          Write-Log -Type "INFO" -Object "Exporting ""$CleanRollUpSolve"" clean-roll-up solve results"
          Export-Results -DatabaseProperties $Properties.Database.Result -Credentials $Properties.Credentials.Result -SolveName $SolveName -ModelName $Properties.HistorisationModelName
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "No clean-roll-up solve is configured"
    }
    # Delete old models
    Write-Log -Type "INFO" -Object "Deleting old models"
    # TODO
  }
}
