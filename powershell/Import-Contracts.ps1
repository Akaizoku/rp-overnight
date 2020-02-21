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
    $ContractPaths = @(
      Join-Path -Path $Properties.InputDataPath -ChildPath "$($Properties.ProcessingDate)\contracts"
      Join-Path -Path $Properties.InputDataPath -ChildPath "$($Properties.ProcessingDate)\NewProduction"
    )
    # Error count variable
    $ErrorCount = 0
  }
  Process {
    Write-Log -Type "INFO" -Object "Importing contract data"
    # Loop through contract data locations
    foreach ($ContractPath in $ContractPaths) {
      # Check if path exists
      if (Test-Path -Path $ContractPath) {
        $Contracts = Get-ChildItem -Path $ContractPath -Filter "*.xml"
        # Check if files are found
        if ($Contracts.Count -ge 1) {
          # Loop through files
          foreach ($Contract in $Contracts) {
            # Import contracts
            Write-Log -Type "INFO" -Object "Importing contract file $($Contract.BaseName)"
            $SolveName = [System.String]::Concat("ImportContracts", "_", $Contract.BaseName, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
            $ImportContracts = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -SolveName $SolveName -FileName $Contract.FullName -Contracts $Properties.Import.Contracts -Counterparties $Properties.Import.Counterparties -SynchronousMode
            # Check outcome
            if ((Test-RiskProBatchClientOutcome -Log $ImportContracts) -eq $false) {
              Write-Log -Type "ERROR" -Object $ImportContracts
              Write-Log -Type "WARN"  -Object "Contract file $($Contract.BaseName) could not be imported"
              $ErrorCount++
              $Global:ErrorCount++
            }
          }
        } else {
          Write-Log -Type "WARN"  -Object "No contract file was found"
        }
      } else {
        Write-Log -Type "ERROR" -Object "Path not found $ContractPath"
        Write-Log -Type "WARN"  -Object "Skipping contracts import"
      }
    }
    # Check if import failed
    if ($ErrorCount -eq $Contracts.Count) {
      Write-Log -Type "WARN" -Object "No contracts could be imported"
    } elseif ($ErrorCount -eq 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount contract file could not be imported"
    } elseif ($ErrorCount -gt 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount contract files could not be imported"
    } else {
      Write-Log -Type "CHECK" -Object "Contracts imported successfully"
    }
  }
}
