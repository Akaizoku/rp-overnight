function Import-Calendars {
  <#
    .SYNOPSIS
    Import calendars

    .DESCRIPTION
    Import calendars in the reference model

    .NOTES
    File name:      Import-Calendars.ps1
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
    Write-Log -Type "INFO" -Object "Importing calendars"
    $CalendarPath = Join-Path -Path $Properties.InputDataPath -ChildPath "$($Properties.ProcessingDate)\calendars"
    # Check if path exists
    if (Test-Path -Path $CalendarPath) {
      $Calendars = Get-ChildItem -Path $CalendarPath -Filter "*.xml"
      # Check if files are found
      if ($Calendars.Count -ge 1) {
        $ErrorCount = 0
        # Loop through files
        foreach ($Calendar in $Calendars) {
          # Import calendar
          Write-Log -Type "DEBUG" -Object "Importing calendar $($Calendar.BaseName)"
          $SolveName = [System.String]::Concat("ImportCalendar", "_", $Calendar.BaseName, "_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
          $ImportCalendars = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ReferenceModelName -SolveName $SolveName -FileName $Calendar.FullName -ModelElements "MERGE" -SynchronousMode
          # Check outcome
          if ((Test-RiskProBatchClientOutcome -Log $ImportCalendars) -eq $false) {
            Write-Log -Type "ERROR" -Object $ImportCalendars
            Write-Log -Type "WARN"  -Object "Calendar $($Calendar.BaseName) could not be imported"
            $ErrorCount++
            $Global:ErrorCount++
          }
        }
        # Check if import failed
        if ($ErrorCount -eq $Calendars.Count) {
          Write-Log -Type "WARN" -Object "No calendar could be imported"
        } elseif ($ErrorCount -eq 1) {
          Write-Log -Type "WARN" -Object "$ErrorCount calendar could not be imported"
        } elseif ($ErrorCount -gt 1) {
          Write-Log -Type "WARN" -Object "$ErrorCount calendars could not be imported"
        } else {
          Write-Log -Type "CHECK" -Object "Calendars imported successfully"
        }
      } else {
        Write-Log -Type "WARN"  -Object "No calendar was found"
      }
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $CalendarPath"
      Write-Log -Type "WARN"  -Object "Skipping calendars import"
    }
  }
}
