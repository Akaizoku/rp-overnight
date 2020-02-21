function Test-Inputs {
  <#
    .SYNOPSIS
    Check inputs

    .DESCRIPTION
    Check the inputs of the overnight process

    .NOTES
    File name:      Test-Inputs.ps1
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
    # Check master model
    Write-Log -Type "INFO" -Object "Checking master model"
    if ((Test-Path -Path $Properties.MasterModelPath) -eq $false) {
      Write-Log -Type "ERROR" -Object "Path not found $($Properties.MasterModelPath)"
      $ErrorCount++
    }
    # Check if inputs exists for the processing date
    Write-Log -Type "INFO" -Object "Checking input data"
    $InputPath = Join-Path -Path $Properties.InputDataPath -ChildPath $ProcessingDate
    if ((Test-Path -Path $InputPath) -eq $false) {
      Write-Log -Type "ERROR" -Object "Path not found $InputPath"
      $ErrorCount++
    }
  }
  End {
    if ($ErrorCount -eq 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount error occurred. Please fix it before proceeding." -ExitCode 1
    } elseif ($ErrorCount -gt 1) {
      Write-Log -Type "WARN" -Object "$ErrorCount error occurred. Please fix it before proceeding." -ExitCode 1
    } else {
      Write-Log -Type "CHECK" -Object "Input checks complete"
    }
  }
}
