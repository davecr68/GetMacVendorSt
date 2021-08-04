Welcome to the Get-macVendorSt project for Windows Powershell.

I wrote up this Powershell script that downloads and parses the IEEE OUI.txt file, which is an identifier of all mac address prefixes assigned by IANA. The oui file is often used by sniffers or other network monitoring to "identify" the MAC address to its vendor. It has also become an excellent way to filter by vendor or OUI prefix.

The included Powershell script "Get-macVendorSt" is a "[St]and-alone version of the Get-macVendor function included in my PowerShell module "IPControl-PSMod". 

I have also created a Powershell application (original files included for those with Powershell Studio") that provides a graphical front end to the data to search and export in various formats.  There is an msi for installing or you may run the EXE directly.

This is a v.01 version so please be forgiving of the coding style and practice. I do this as a hobby and to benefit my customers who are looking to do similar things, and who DO have professional developers. :)

Syntax is straight forward: Get-macVendorSt {-macsearch|-vendorsearch|

E.g. Get-macVendorSt -vendorsearch apple

Security and requirements for PS: If for any reason you are presented with an error regarding permissions, you may need run the following in an Administrator Powershell:

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned


Thanks and good luck. Let me know if you encounter any issues.
~DC
