
<#
	.SYNOPSIS
		Provides a lookup of the mac address or vendor by parsing a pre-compiled oui.txt file from IEEE
	
	.DESCRIPTION
		Get-macVendorSt takes a mac address as a input value and returns the Vendor, or takes a vendor as an argument and returns a list of all mac address prefixes that match the vendor (any part) string.
	
	.PARAMETER macSearch
		A description of the macSearch parameter.
	
	.PARAMETER vendorSearch
		A description of the vendorSearch parameter.
	
	.PARAMETER ageCheck
		A description of the ageCheck parameter.
	
	.NOTES
		Other derivatives are out there for sniffers and other scripts
#>
function Get-macVendorSt
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		[string[]]$macSearch,
		[Parameter(Mandatory = $false)]
		[string]$vendorSearch,
		[int]$ageCheck = 7,
		[switch]$refreshOnly
	)
	
	#End Param
	
	
	Process
	{
		#Check the OS and set $_dir to the slash or back slash notation
		$_dir = ""
		
		if ($PSVersionTable.OS -and $PSVersionTable.OS -match "Linux")
		{
			$_dir = "~/.bt.diamondip"
			$_outFile = "oui.txt"
			$_path = "$_dir/$_outFile"
			$_processed = "$_dir/processed_oui.txt"
		}
		else
		{
			$_dir = "~\Documents\.bt.diamondip"
			$_outFile = "oui.txt"
			$_path = "$_dir\$_outFile"
			$_processed = "$_dir\processed_oui.txt"
		}
		
		#If the users mac Address table does not exist, download and create it.
		if (!(Test-Path -PathType Any $_path))
		{
			#Write-Output "[WARN] The oui.txt file was not found. Attempting to download now ..."
			#Invoke-RestMethod -Method GET -Uri "http://standards-oui.ieee.org/oui.txt" -OutFile $_path
			Get-OuiFileProcess -ouiFile $true
		}
		else
		{
			if ($refreshOnly.IsPresent -eq $true)
			{
				#Write-Output "[WARN] This file is older than $ageCheck days. Downloading new version now..."
				#rm -Path $_path -ErrorAction SilentlyContinue
				#rm -Path $_processed -ErrorAction SilentlyContinue
				#Invoke-RestMethod -Method GET -Uri "http://standards-oui.ieee.org/oui.txt" -OutFile $_path
				Get-OuiFileProcess -ouiFile $true
				
			}
			else
			{
				#Write-Output "[INFO] Oui.txt file found. Checking Age of file ..."
				$fileDate = (Get-Item $_path).CreationTime
				$thisdate = Get-Date
				if (($fileDate.AddDays($ageCheck)) -lt $thisdate)
				{
					#Write-Output "[WARN] This file is older than $ageCheck days. Downloading new version now..."
					#rm -Path $_path -ErrorAction SilentlyContinue
					#rm -Path $_processed -ErrorAction SilentlyContinue
					#Invoke-RestMethod -Method GET -Uri "http://standards-oui.ieee.org/oui.txt" -OutFile $_path
					Get-OuiFileProcess -ouiFile $file
				}
			}
			
		}
		
		
		if (!(Test-Path -PathType Any $_processed) -or $refreshOnly.IsPresent -eq $true)
		{
			Get-OuiFileProcess -processFile $true
		}
		
		$MacContents = Import-Csv -Path $_processed -Header "OUI", "VENDOR" -Delimiter "|"
		
		[string[]]$foundMacList = ""
		
		if ($macSearch)
		{
			
			#Below is a good mac RX that checks for a full mac delimited
			#$macRx = ($macSearch | Select-String -Pattern "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$")
			
			
			foreach ($mac in $macSearch)
			{
				if ($mac -gt '')
				{
					$macAddr = ($mac.ToString().ToUpper() | foreach { $_ -replace "[:-]", "" })
					$macSearchString = $macAddr.Substring(0, 6)
					
					#$foundMac = (Get-Content "~/processed_oui.txt" -ErrorAction ignore | select-string -Pattern $macSearchString)   
					$foundMac = ($MacContents | Select-Object -Property OUI, VENDOR | Where-Object OUI -match $macSearchString)
				}
				if ($foundMac)
				{
					Write-Output $foundMac
					
				}
				else
				{
					Write-Output "MAC Not Found: $macSearch"
				}
				
			}
			
		}
		
		
		if ($vendorSearch -gt '')
		{
			
			#This is a search for the vendor to return all mac addresses
			#$foundVendor = (Get-Content "~/processed_oui.txt" -ErrorAction ignore | select-string -Pattern $vendorSearch) 
			
			$foundVendor = ($MacContents | Select-Object -Property OUI, VENDOR | Where-Object VENDOR -match $vendorSearch)
			
			if ($foundVendor)
			{
				$foundVendor
			}
			else
			{
				Write-Output "Vendor Not Found: $vendorSearch"
			}
		}
	}
}

function Get-OuiFileProcess
{
	[CmdletBinding()]
	param (
		[boolean]$ouiFile = $false,
		[boolean]$processFile = $false
	)
	Process
	{
		$inPath = "$env:USERPROFILE\Documents\.bt.diamondip\oui.txt"
		$outPath = "$env:USERPROFILE\Documents\.bt.diamondip\processed_oui.txt"
		
		if (!(Test-Path -Path $inPath -PathType Any))
		{
			#Write-Output "[WARN] The oui.txt file was not found. Attempting to download now ..."
			Invoke-RestMethod -Method GET -Uri "http://standards-oui.ieee.org/oui.txt" -OutFile $inPath
			
		}
		else
		{
			if ($ouiFile -eq $true)
			{
				#Write-Output "[WARN] The oui.txt file was not found. Attempting to download now ..."
				rm $inPath
				Invoke-RestMethod -Method GET -Uri "http://standards-oui.ieee.org/oui.txt" -OutFile $inPath
			}
		}
		
		if (Test-Path -Path $outPath -PathType any)
		{
			if ($processFile -eq $true)
			{
				rm -Path $outPath
			}
			
		}
		
		$sr = New-Object -TypeName System.IO.StreamReader -ArgumentList $inPath
		$sw = New-Object -TypeName System.IO.StreamWriter -ArgumentList $outPath
		
		$sw.WriteLine("OUI|VENDOR")
		
		
		while ($sr.Peek() -gt 0)
		{
			$outline = @()
			$line = $sr.ReadLine()
			if ($line -match "base 16")
			{
				
				$reg = '\b(\w*.\w*\w*.)\b'
				
				$found = $line -match $reg
				
				$myMatch = ""
				$oui = ""
				$rest = ""
				$ouistr = ""
				
				If ($found)
				{
					$myMatch = [regex]::matches($line, $reg)
					$oui = $myMatch[0]
					$rest = $myMatch[2 .. $myMatch.Count] -join ""
					$ouistr = "$oui|$rest"
					#[System.io.file]::AppendAllText($processed,$ouistr)
					$sw.WriteLine($ouistr)
				}
			}
		}
		
		$sr.Dispose()
		$sw.Dispose()
	}
}