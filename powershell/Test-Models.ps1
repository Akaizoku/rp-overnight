function Test-Models {
  <#
    .SYNOPSIS
    Check models

    .DESCRIPTION
    Check models impacted by the overnight process

    .NOTES
    File name:      Test-Models.ps1
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
    # Initialise error counter
    $ErrorCount = 0
  }
  Process {
    # Check if production model already exists
    Write-Log -Type "INFO" -Object "Checking production model"
    $TestProductionModel = Test-Model -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName
    if ($TestProductionModel -eq $true) {
      Write-Log -Type "ERROR" -Object "Production model ""$($Properties.ProductionModelName)"" already exists"
      if ($Properties.Attended) {
        $Confirm = Confirm-Prompt -Prompt "Do you want to remove the existing production model ""$($Properties.ProductionModelName)""?"
      }
      if (($Properties.Attended -eq $false) -Or $Confirm) {
        # Remove existing production model
        Write-Log -Type "WARN" -Object "Removing existing production model ""$($Properties.ProductionModelName)"""
        $ModelDeletion = Invoke-DeleteModel -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -Name $Properties.ProductionModelName
        if ((Test-RiskProBatchClientOutcome -Log $ModelDeletion) -eq $false) {
          Write-Log -Type "ERROR" -Object $ModelDeletion
          Write-Log -Type "WARN"  -Object "Production model ""$($Properties.ProductionModelName)"" could not be removed" -ExitCode 1
          $ErrorCount++
        }
      } else {
        # Record error
        $ErrorCount++
      }
    }
    # Check reference model
    Write-Log -Type "INFO" -Object "Checking reference model"
    $TestReferenceModel = Test-Model -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ReferenceModelName
    if ($TestReferenceModel -eq $false) {
      Write-Log -Type "ERROR" -Object "Reference model ""$($Properties.ReferenceModelName)"" does not exist"
      $ErrorCount++
    }
    # Check if historisation model exists
    Write-Log -Type "INFO" -Object "Checking historisation model"
    $TestHistorisationModel = Test-Model -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.HistorisationModelName
    if ($TestHistorisationModel -eq $false) {
      Write-Log -Type "ERROR" -Object "Historisation model ""$($Properties.HistorisationModelName)"" does not exist"
      $ErrorCount++
    }
  }
  End {
    if ($ErrorCount -eq 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount error occurred. Please fix it before proceeding." -ExitCode 1
    } elseif ($ErrorCount -gt 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount error occurred. Please fix it before proceeding." -ExitCode 1
    } else {
      Write-Log -Type "CHECK" -Object "Model checks complete"
    }
  }
}
