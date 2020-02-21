function Start-Historisation {
  <#
    .SYNOPSIS
    Start Historisation

    .DESCRIPTION
    Launch Historisation

    .NOTES
    File name:      Start-Historisation.ps1
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
    $HistorisationSolves  = $Properties.Solves | Where-Object -Property "Solve kind" -CEQ -Value "Historisation"  | Select-Object -ExpandProperty "Solve name"
    $RollUpSolves         = $Properties.Solves | Where-Object -Property "Solve kind" -CEQ -Value "Rollup"         | Select-Object -ExpandProperty "Solve name"
  }
  Process {
    Write-Log -Type "INFO" -Object "Starting historisation process"
    # --------------------------------------------------------------------------
    # Historisation solves
    # --------------------------------------------------------------------------
    if ($HistorisationSolves -ge 1) {
      foreach ($HistorisationSolve in $HistorisationSolves) {
        Write-Log -Type "INFO" -Object "Starting historisation solve ""$HistorisationSolve"""
        # Define solve properties
        $SolveProperties  = $Properties.Solves | Where-Object -Property "Solve name" -CEQ -Value $HistorisationSolve
        $SolveName        = [System.String]::Concat($HistorisationSolve, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $AnalysisDate     = [System.String]::Concat($Properties.AnalysisDate, " ", $SolveProperties.("Analysis date convention"))
        # Run historisation solve
        # TODO handle dynamic historisation solves
        $RunHistorisationSolve = Start-Solve -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -ResultSelection $HistorisationSolve -AccountStructure $Properties.AccountStructureName -SolveName $SolveName -AnalysisDate $AnalysisDate -DataGroups $SolveProperties.("Data groups") -DataFilters $SolveProperties.("Data filters") -Separator $SolveProperties.("Separator") -Kind "Static" -SynchronousMode
        Assert-RiskProBatchClientOutcome -Log $RunHistorisationSolve -Object "Historisation solve ""$HistorisationSolve""" -Verb "run" -IrregularForm "run"
        # Save results
        if ($Properties.UseResultDatabase -eq $true) {
          Write-Log -Type "INFO" -Object "Exporting ""$HistorisationSolve"" historisation analysis results"
          Export-Results -DatabaseProperties $Properties.Database.Result -Credentials $Properties.Credentials.Result -SolveName $SolveName -ModelName $Properties.ProductionModelName
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "No historisation solve is configured"
    }
    # --------------------------------------------------------------------------
    # Roll-up solves
    # --------------------------------------------------------------------------
    if ($RollUpSolves -ge 1) {
      foreach ($RollUpSolve in $RollUpSolves) {
        Write-Log -Type "INFO" -Object "Starting roll-up solve ""$RollUpSolve"""
        # Define solve properties
        $SolveProperties  = $Properties.Solves | Where-Object -Property "Solve name" -CEQ -Value $RollUpSolve
        $SolveName        = [System.String]::Concat($RollUpSolve, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $AnalysisDate     = [System.String]::Concat($Properties.AnalysisDate, " ", $SolveProperties.("Analysis date convention"))
        # Run historisation solve
        # TODO handle dynamic historisation solves
        $RunRollUpSolve = Start-RollupSolve -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.HistorisationModelName -ResultSelection $RollUpSolve -SolveName $SolveName -AnalysisDate $AnalysisDate -SynchronousMode
        Assert-RiskProBatchClientOutcome -Log $RunRollUpSolve -Object "Roll-up solve ""$RollUpSolve""" -Verb "run" -IrregularForm "run"
        # Save results
        if ($Properties.UseResultDatabase -eq $true) {
          Write-Log -Type "INFO" -Object "Exporting ""$RollUpSolve"" roll-up solve results"
          Export-Results -DatabaseProperties $Properties.Database.Result -Credentials $Properties.Credentials.Result -SolveName $SolveName -ModelName $Properties.HistorisationModelName
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "No roll-up solve is configured"
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "Historisation process complete"
  }
}
