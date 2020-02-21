function Publish-MasterModel {
  <#
    .SYNOPSIS
    Upload master model

    .DESCRIPTION
    Upload master model to the server

    .NOTES
    File name:      Publish-MasterModel.ps1
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
    Write-Log -Type "INFO" -Object "Uploading master model"
    # Check master model
    if (Test-Path -Path $Properties.MasterModelPath) {
      # Upload model
      $Upload = Invoke-Upload -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -FilePath $Properties.MasterModelPath -DestinationPath "Public_Folder/Input_Data"
      Assert-RiskProBatchClientOutcome -Log $Upload -Object "Master model" -Verb "upload"
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $($Properties.MasterModelPath)"
      Write-Log -Type "WARN"  -Object "Master model could not be uploaded" -ExitCode 1
    }
  }
}
