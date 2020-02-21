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
    # Define market data input path
    $MarketDataPath = Join-Path -Path $Properties.InputDataPath -ChildPath "$($Properties.ProcessingDate)\market"
  }
  Process {
    Write-Log -Type "INFO" -Object "Importing observations"
    # Check if path exists
    if (Test-Path -Path $MarketDataPath) {
      $Observations = Get-ChildItem -Path $MarketDataPath -Filter "*.xml"
      # Check if files are found
      if ($Observations.Count -ge 1) {
        $ErrorCount = 0
        # Loop through files
        foreach ($Observation in $Observations) {
          # Import observations
          Write-Log -Type "DEBUG" -Object "Importing observations $($Observation.BaseName)"
          $SolveName = [System.String]::Concat("ImportObservations_", $Observation.BaseName, (Get-Date -Format "yyyy-MM-dd_HHmmss"))
          $ImportObservations = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ReferenceModelName -SolveName $SolveName -FileName $Observation.FullName -ModelElements "MERGE" -SynchronousMode
          # Check outcome
          if ((Test-RiskProBatchClientOutcome -Log $ImportObservations) -eq $false) {
            Write-Log -Type "ERROR" -Object $ImportObservations
            Write-Log -Type "WARN"  -Object "Observations $($Observation.BaseName) could not be imported"
            $ErrorCount++
          }
        }
        # Check if import failed
        if ($ErrorCount -eq $Observations.Count) {
          Write-Log -Type "WARN" -Object "No observations could be imported"
        } elseif ($ErrorCount -eq 1) {
          Write-Log -Type "WARN" -Object "$ErrorCount observation could not be imported"
        } elseif ($ErrorCount -gt 1) {
          Write-Log -Type "WARN" -Object "$ErrorCount observations could not be imported"
        } else {
          Write-Log -Type "CHECK" -Object "Observations imported successfully"
        }
      } else {
        Write-Log -Type "WARN"  -Object "No observation was found"
      }
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $MarketDataPath"
      Write-Log -Type "WARN"  -Object "Skipping observations import"
    }
  }
}
