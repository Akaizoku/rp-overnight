function Initialize-ProductionModel {
  <#
    .SYNOPSIS
    Create production model

    .DESCRIPTION
    Create new production model from the master model

    .NOTES
    File name:      Initialize-ProductionModel.ps1
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
    # Create blank model
    Write-Log -Type "INFO" -Object "Creating production model"
    $CreateModel = Invoke-CreateModel -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -Type "PRODUCTION" -Description $Properties.ProductionModelDescription -Currency $Properties.ModelCurrency -ModelGroupName $Properties.ProductionModelGroup
    Assert-RiskProBatchClientOutcome -Log $CreateModel -Object """$($Properties.ProductionModelName)"" model" -Verb "create"
    # Import master model elements
    Write-Log -Type "INFO" -Object "Importing master model"
    $SolveName = [System.String]::Concat("ImportMasterModel_", (Get-Date -Format "yyyy-MM-dd_HHmmss"))
    $ImportModelElements = Start-ImportXML -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -SolveName $SolveName -FileName $Properties.PublicMasterModel -ModelElements "MERGE" -Libraries $Properties.Import.Libraries -SynchronousMode
    Assert-RiskProBatchClientOutcome -Log $ImportModelElements -Object "Master model" -Verb "import"
    # Generate UDA JAR and update database
    Write-Log -Type "INFO" -Object "Updating user-defined attributes (UDA)"
    $UpdateUDA = Start-GenerateUDAJAR -JavaPath $Properties.JavaPath -RiskProBatchClient $Properties.RiskProBatchClientPath -ServerURI $Properties.ServerURI -Credentials $Properties.Credentials.RiskPro -JavaOptions $Properties.JavaOptions -ModelName $Properties.ProductionModelName -GenerateJAR -UpdateDatabase -SynchronousMode
    Assert-RiskProBatchClientOutcome -Log $UpdateUDA -Object "User-defined attributes" -Verb "update"
  }
}
