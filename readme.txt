These scripts are just a collection of scripts for doing various sorts of reports from VMWare.

As such, you need POWERSHELL 4 or above and POWERCLI. (https://developercenter.vmware.com/tool/vsphere_powercli/6.0)

These scripts don't have much error handling so if you don't have the right versions of powershell or powercli, it'll most likely fail in a very ungraceful manner.

esxi summary.ps1 - This script provides a basic "health" check of the environment. It'll list things like VM's with snapshots and other misconfigurations.

ESXi Capacity Report.ps1 - This script will list the remaining vCPU and RAM capacity on ESXi hosts (if any!). It should be used to help decide where new VM's can go.
