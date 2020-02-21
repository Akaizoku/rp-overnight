#Requires -Version 3.0

<#
  .SYNOPSIS
  Start RiskPro Overnight

  .DESCRIPTION
  Start the automation of the Overnight process for OneSumX for Risk Management

  .PARAMETER ProcessingDate
  The optional processing date parameter corresponds to the reporting date. The default value is d-1.

  .INPUTS
  System.String. You can pipe the date to Start-Overnight.

  .OUTPUTS
  None. Start-Overnight does not return any value.

  .NOTES
  File name:      Start-Overnight.ps1
  Author:         Florian CARRIER
  Creation date:  17/02/2020
  Last modified:  17/02/2020
  Dependencies:   - PowerShell Tool Kit (PSTK)
                  - RiskPro PowerShell Module (PSRP)
                  - SQL Server PowerShell Module (SQLServer)

  .LINK
  https://github.com/Akaizoku/rp-overnight

  .LINK
  https://www.powershellgallery.com/packages/PSTK

  .LINK
  https://www.powershellgallery.com/packages/PSRP

  .LINK
  https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module

  .LINK
  http://wolterskluwerfs.com

  .LINK
  http://www.wolterskluwerfs.com/risk/home.aspx
#>

# ------------------------------------------------------------------------------
# Parameters
# ------------------------------------------------------------------------------
[CmdletBinding (
  SupportsShouldProcess = $true
)]
Param (
  [Parameter (
    Position    = 1,
    Mandatory   = $false,
    HelpMessage = "Processing date ('yyyyMMdd')",
    ValueFromPipeline               = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [ValidatePattern ('\d{8}')]
  [System.String]
  $ProcessingDate = (Get-Date -Date (Get-Date).AddDays(-1) -Format "yyyyMMdd"),
  [Parameter (
    HelpMessage = "Run script in unattended mode"
  )]
  [Switch]
  $Unattended
)

Begin {
  # ----------------------------------------------------------------------------
  # Global preferences
  # ----------------------------------------------------------------------------
  Set-StrictMode -Version Latest
  $ErrorActionPreference  = "Stop"
  # $DebugPreference        = "Continue"

  # ----------------------------------------------------------------------------
  # Global variables
  # ----------------------------------------------------------------------------
  # General
  $WorkingDirectory   = $PSScriptRoot
  $ISOTimeStamp       = Get-Date -Format "yyyy-MM-dd_HHmmss"

  # Configuration
  $ConfDirectory      = Join-Path -Path $WorkingDirectory -ChildPath "conf"
  $LibDirectory       = Join-Path -Path $WorkingDirectory -ChildPath "lib"
  $LogDirectory       = Join-Path -Path $WorkingDirectory -ChildPath "log"
  $TmpDirectory       = Join-Path -Path $WorkingDirectory -ChildPath "tmp"
  $DefaultProperties  = Join-Path -Path $ConfDirectory    -ChildPath "default.ini"
  $CustomProperties   = Join-Path -Path $ConfDirectory    -ChildPath "custom.ini"
  $ImportProperties   = Join-Path -Path $ConfDirectory    -ChildPath "import.ini"
  $SolveProperties    = Join-Path -Path $ConfDirectory    -ChildPath "solves.csv"

  # ----------------------------------------------------------------------------
  # Modules
  # ----------------------------------------------------------------------------
  $Modules = @("PSTK", "PSRP", "SQLServer")
  foreach ($Module in $Modules) {
    # Workaround for issue RPD-2
    $Force = $Module -ne "SQLServer"
    try {
      # Check if module is installed
      Import-Module -Name "$Module" -Force:$Force -ErrorAction "Stop"
      Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded."
    } catch {
      # If module is not installed then check if package is available locally
      try {
        Import-Module -Name (Join-Path -Path $LibDirectory -ChildPath $Module) -ErrorAction "Stop" -Force:$Force
        Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded from the library directory."
      } catch {
        Throw "The $Module library could not be loaded. Make sure it has been made available on the machine or manually put it in the ""$LibDirectory"" directory"
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Script configuration
  # ----------------------------------------------------------------------------
  # General settings
  $Properties = Import-Properties -Path $DefaultProperties -Custom $CustomProperties

  # ----------------------------------------------------------------------------
  # Start script
  # ----------------------------------------------------------------------------
  # Generate transcript
  $Transcript = Join-Path -Path $LogDirectory -ChildPath "Overnight_${ISOTimeStamp}.log"
  Start-Script -Transcript $Transcript

  # Log command line
  Write-Log -Type "DEBUG" -Object $PSCmdlet.MyInvocation.Line

  # Create temporary directory
  if ((Test-Path -Path $TmpDirectory) -eq $false) {
    Write-Log -Type "DEBUG" -Object "Creating temporary directory"
    New-Item -Path $TmpDirectory -ItemType "Directory" | Out-Null
  }

  # ----------------------------------------------------------------------------
  # Functions
  # ----------------------------------------------------------------------------
  # Load PowerShell functions
  $Functions = Get-ChildItem -Path (Join-Path -Path $WorkingDirectory -ChildPath "powershell")
  foreach ($Function in $Functions) {
    Write-Log -Type "DEBUG" -Object "Import $($Function.Name)"
    try   { . $Function.FullName }
    catch { Write-Error -Message "Failed to import function $($Function.FullName): $_" }
  }

  # ----------------------------------------------------------------------------
  # Variables
  # ----------------------------------------------------------------------------
  # Execution type switch
  $Properties.Attended = -Not $Unattended

  # (Re)load environment variables
  Write-Log -Type "DEBUG" -Object "Load environment variables"
  $EnvironmentVariables = @(
    $Properties.RiskProHomeVariable,
    $Properties.JavaHomeVariable
  )
  foreach ($EnvironmentVariable in $EnvironmentVariables) {
    Sync-EnvironmentVariable -Name $EnvironmentVariable -Scope "MACHINE" | Out-Null
  }

  # Java
  if ((-Not $Properties.JavaPath) -Or ($Properties.JavaPath -eq "") -Or ($Properties.JavaPath -eq $null)) {
    if (Test-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope "MACHINE") {
      Write-Log -Type "DEBUG" -Object "Java path not specified. Defaulting to $($Properties.JavaHomeVariable)"
      $JavaHome = Get-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope "MACHINE"
      $Properties.JavaPath = Join-Path -Path $JavaHome -ChildPath "bin\java.exe"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.JavaHomeVariable) environment variable does not exist"
      Write-Log -Type "WARN"  -Object "Please setup $($Properties.JavaHomeVariable) or specify the Java path in the configuration files" -ExitCode 1
    }
  }

  # Java options
  $JavaOptions = New-Object -TypeName "System.Collections.ArrayList"
  # WARNING use quotes to avoid parsing issue due to dots ("Could not find or load main class .io.tmpdir")
  [Void]$JavaOptions.Add('-D"java.io.tmpdir"="' + $TmpDirectory + '"')
  # Add heap size if specified
  if ($Properties.HeapSize) { [Void]$JavaOptions.Add('-Xmx' + $Properties.HeapSize) }
  $Properties.Add("JavaOptions", $JavaOptions)

  # RiskPro batch client
  if ((-Not $Properties.RiskProBatchClientPath) -Or ($Properties.RiskProBatchClientPath -eq "") -Or ($Properties.RiskProBatchClientPath -eq $null)) {
    if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope "MACHINE") {
      Write-Log -Type "DEBUG" -Object "RiskPro batch client path not specified. Defaulting to $($Properties.RiskProHomeVariable)"
      $JavaHome = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope "MACHINE"
      $Properties.RiskProBatchClientPath = Join-Path -Path $JavaHome -ChildPath "bin\riskpro-batch-client.jar"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.RiskProHomeVariable) environment variable does not exist"
      Write-Log -Type "WARN"  -Object "Please setup $($Properties.RiskProHomeVariable) or specify the RiskPro batch client path in the configuration files" -ExitCode 1
    }
  }

  # RiskPro server URI
  $Properties.ServerURI = Get-URI -Scheme $Properties.ApplicationServerProtocol -Authority ($Properties.ApplicationServerHostname + ':' + $Properties.ApplicationServerPort) -Path $Properties.WebApplicationName

  # Master model server-side location
  $MasterModelName = Split-Path -Path $Properties.MasterModelPath -Leaf
  $Properties.PublicMasterModel = [System.String]::Concat("riskpro://Public_Folder/Input_Data/", $MasterModelName)

  # Database properties
  $Properties.Database = Import-Properties -Path (Join-Path -Path $ConfDirectory -ChildPath "database.ini") -Section

  # Processing date
  $Properties.ProcessingDate = $ProcessingDate
  $Properties.AnalysisDate   = [Datetime]::ParseExact($ProcessingDate, "yyyyMMdd", $null).ToString("d/M/yyyy")

  # Define model name
  $Properties.ProductionModelName        = [System.String]::Concat($Properties.ProductionModelPrefix, "_", $Properties.ProcessingDate)
  $Properties.ProductionModelDescription = [System.String]::Concat("Production model ", $Properties.ProcessingDate)

  # Import properties
  $Properties.Import = Import-Properties -Path $ImportProperties

  # Solves properties
  $Properties.Solves = Import-Csv -Path $SolveProperties -Delimiter ","

  # Instantiate global error count
  $Global:ErrorCount = 0

  # ----------------------------------------------------------------------------
  # Security
  # ----------------------------------------------------------------------------
  # Encryption key
  $EncryptionKey = Get-Content -Path (Join-Path -Path $WorkingDirectory -ChildPath "res\security\encryption.key") -Encoding "UTF8"
  $Properties.Credentials = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
  # Log database user credentials
  $Properties.Credentials.Add("Log", (Get-ScriptCredentials -UserName $Properties.Database.Log.DatabaseUsername -Password $Properties.Database.Log.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "log database user" -Unattended:$Unattended))
  # Result database user credentials
  $Properties.Credentials.Add("Result", (Get-ScriptCredentials -UserName $Properties.Database.Result.DatabaseUsername -Password $Properties.Database.Result.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "result database user" -Unattended:$Unattended))
  # RiskPro automation user credentials
  $Properties.Credentials.Add("RiskPro", (Get-ScriptCredentials -UserName $Properties.AutomationUserName -Password $Properties.AutomationUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro automation user" -Unattended:$Unattended))
}
# ------------------------------------------------------------------------------
Process {
  Write-Log -Type "INFO" -Object "Starting Overnight process as of date $ProcessingDate"
  Test-Prerequisites          -Properties $Properties
  Publish-MasterModel         -Properties $Properties
  Import-MarketData           -Properties $Properties
  Initialize-ProductionModel  -Properties $Properties
  Import-Contracts            -Properties $Properties
  Start-Solves                -Properties $Properties
  Start-Historisation         -Properties $Properties
  Start-AutomationMaintenance -Properties $Properties
  Send-ValidationEmail        -Properties $Properties
  # Check outcome
  if ($Global:ErrorCount -ge 1) {
    Write-Log -Type "WARN" -Object "Overnight process completed with errors"
  } else {
    Write-Log -Type "CHECK" -Object "Overnight process completed successfully"
  }
}
# ------------------------------------------------------------------------------
End {
  Start-CleanUp -Properties $Properties -TmpDirectory $TmpDirectory
  # End script gracefully
  Stop-Script -ExitCode 0
}
