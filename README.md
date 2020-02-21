# RiskPro Overnight Automation

`rp-overnight` is a small utility script to help manage and automate the Overnight loading process into OneSumX for Risk Management.

## Security

When running in unattended mode, the script will use the credentials provided in the configuration files. The passwords provided **must** be stored as a plain-text representation of a secure string.

In order to generate the required value, please use the command below with the corresponding password:

```powershell
ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String "<password>" -AsPlainText -Force) -Key (Get-Content -Path ".\res\security\encryption.key")
```
