function Start-Solves {
  <#
    .SYNOPSIS
    Start solves

    .DESCRIPTION
    Launch solves

    .NOTES
    File name:      Start-Solves.ps1
    Author:         Florian CARRIER
    Creation date:  18/02/2020
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
    # List solves
    $StaticSolves   = $Properties.Solves | Where-Object -Property "Solve kind" -CEQ -Value "Static"   | Select-Object -ExpandProperty "Solve name"
    $DynamicSolves  = $Properties.Solves | Where-Object -Property "Solve kind" -CEQ -Value "Dynamic"  | Select-Object -ExpandProperty "Solve name"
    # Define data group
    $DataGroup      = [System.String]::Concat($Properties.LotType, "-", $Properties.ProcessingDate)
  }
  Process {
    # Loop through static solves
    Write-Log -Type "INFO" -Object "Running static solves"
    if ($StaticSolves -ge 1) {
      foreach ($StaticSolve in $StaticSolves) {
        Write-Log -Type "INFO" -Object "Running static analysis ""$StaticSolve"""
        # Define solve properties
        $SolveProperties  = $Properties.Solves | Where-Object -Property "Solve name" -CEQ -Value $StaticSolve
        $SolveName        = [System.String]::Concat($StaticSolve, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $AnalysisDate     = [System.String]::Concat($Properties.AnalysisDate, " ", $SolveProperties.("Analysis date convention"))
        # Run static solve
        $RunStaticSolve = Start-Solve -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -ResultSelection $StaticSolve -AccountStructure $Properties.AccountStructureName -SolveName $SolveName -AnalysisDate $AnalysisDate -DataGroups $DataGroup -DataFilters $SolveProperties.("Data filters") -Separator $SolveProperties.("Separator") -Kind "Static" -SynchronousMode
        Assert-RiskProBatchClientOutcome -Log $RunStaticSolve -Object """$StaticSolve"" static analysis" -Verb "run" -IrregularForm "run"
        # Save results
        if ($Properties.UseResultDatabase -eq $true) {
          Write-Log -Type "INFO" -Object "Exporting ""$StaticSolve"" static analysis results"
          Export-Results -DatabaseProperties $Properties.Database.Result -Credentials $Properties.Credentials.Result -SolveName $SolveName -ModelName $Properties.ProductionModelName
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "No static solve is configured"
    }
    # Loop through dynamic solves
    Write-Log -Type "INFO" -Object "Running dynamic solves"
    if ($DynamicSolves -ge 1) {
      foreach ($DynamicSolve in $DynamicSolves) {
        Write-Log -Type "INFO" -Object "Running dynamic analysis ""$DynamicSolve"""
        # Define solve properties
        $SolveProperties  = $Properties.Solves | Where-Object -Property "Solve name" -CEQ -Value $DynamicSolve
        $SolveName        = [System.String]::Concat($DynamicSolve, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $AnalysisDate     = [System.String]::Concat($Properties.AnalysisDate, " ", $SolveProperties.("Analysis date convention"))
        # Run dynamic solve
        $RunDynamicSolve = Start-Solve -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -ResultSelection $DynamicSolve -AccountStructure $Properties.AccountStructureName -SolveName $SolveName -AnalysisDate $AnalysisDate -DataGroups $DataGroup -DataFilters $SolveProperties.("Data filters") -Separator $SolveProperties.("Separator") -Kind "Dynamic" -SynchronousMode
        Assert-RiskProBatchClientOutcome -Log $RunDynamicSolve -Object """$DynamicSolve"" dynamic analysis" -Verb "run" -IrregularForm "run"
        # Save results
        if ($Properties.UseResultDatabase -eq $true) {
          Write-Log -Type "INFO" -Object "Exporting ""$DynamicSolve"" dynamic analysis results"
          Export-Results -DatabaseProperties $Properties.Database.Result -Credentials $Properties.Credentials.Result -SolveName $SolveName -ModelName $Properties.ProductionModelName
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "No dynamic solve is configured"
    }
  }
}
