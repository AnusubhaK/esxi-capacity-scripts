#Basic script to pull stuff out of VMWare for a weekly style report.

$erroractionpreference= 'continue'
Add-PSSnapin VMware.VimAutomation.Core
$erroractionpreference= 'stop'
clear-host

#First step, what is the name of VCentre?
$name = Read-Host 'What vcenter server do you want to connect to?'
connect-viserver $name

#Lets now get the date and time as a report really needs that
$timecode=get-date


#Now get a list of the ESXi hosts listed in VCentre
$esxi_hosts=get-vmhost |sort-object name

clear

#`r`n is carriage return and a new line
Write-host -nonewline "VMWare host status report for " $timecode `r`n `r`n

#Loop through the hosts

write-host "VMWare vCPU:pCPU oversubscription Ratio"

ForEach ($esxi_host in $esxi_hosts) {

	#Grab a total of the number of CPU's allocated to each VM
	$vm_num_cpus=get-vm -location $esxi_host |measure-object -sum numcpu |fl sum |out-string
	
	$vm_num_cpus=$vm_num_cpus.trim()
	$vm_num_cpus=$vm_num_cpus.trim("Sum : ")
	#$vm_num_cpus
	
	$phys_host_cpus=get-vmhost -name $esxi_host|fl numcpu |out-string
	$phys_host_cpus=$phys_host_cpus.trim()
	$phys_host_cpus=$phys_host_cpus.trim("NumCpu : ")
	$phys_cpu_ratio=([int]$vm_num_cpus / $phys_host_cpus)
	
	$esxi_hostname=$esxi_host |fl name |out-string
	$esxi_hostname=$esxi_hostname.trim() |out-string

	$output=$esxi_hostname
	$output +=$phys_cpu_ratio
	$output +=":1"
	
	write-host $output `r`n `r`n
}
	
write-host "NOTE: This report takes into account VM's that are both OFF and suspended. If the VM exists, it is included."

write-host "----------------------------------------------------------"

write-host "VMWare Memory Allocation"

#$esxi_hosts=get-vmhost
ForEach ($esxi_host in $esxi_hosts) {

$vm_sum_ram=get-vm -location $esxi_host |measure-object -sum memorygb |fl sum |out-string

#trim out CR+LF and the Sum part of the output
$vm_sum_ram=$vm_sum_ram.trim()
$vm_sum_ram=$vm_sum_ram.trim("Sum : ")

write-host "ESXi Host" $esxi_host "has " $vm_sum_ram "GB allocated to VM's"

#Now get the RAM in the host
$esxi_host_ram=get-vmhost $esxi_host |fl memorytotalgb |out-string

#and to trim it
$esxi_host_ram=$esxi_host_ram.trim()
$esxi_host_ram=$esxi_host_ram.trim("MemoryTotalGB : ")

#Now lets convert the strings to ints

$esxi_host_ram=[int]$esxi_host_ram
$vm_sum_ram=[int]$vm_sum_ram

#$pattern = "`r"
#$esxi_host_ram=$esxi_host_ram -replace $pattern,''
#$vm_sum_ram -replace $pattern,''
#$pattern = "`n"
#$esxi_host_ram=$esxi_host_ram -replace $pattern,''
#$vm_sum_ram -replace $pattern,''
#$esxi_host_ram=[convert]::Toint32($esxi_host_ram,2)
#$vm_sum_ram=[convert]::Toint32($vm_sum_ram,2)


if ($vm_sum_ram -gt $esxi_host_ram) {write-host "Host " $esxi_host "is overcomitted on RAM byclsc" ($vm_sum_ram-$esxi_host_ram) "GB and could Balloon"}
#write-host $vm_sum_ram
#write-host $esxi_host_ram

write-host "----------------------------------------------------------"

#write-host $ram_out
}


#Let's find where VCentre is living, we are assuming that VCentre has the default name "VMWare Vcentre server appliance"
$Vcentre=get-vm vmware* |fl host |out-string
Write-host "VCentre is currently running on" $Vcentre `r`n `r`n 

write-host "----------------------------------------------------------"

#List out VM's with snapshots
$snapshots=get-vm |get-snapshot |fl VM,sizegb |out-string
Write-host "VM's that have active snapshots" `r`n `r`n 
Write-host $snapshots `r`n `r`n  

write-host "----------------------------------------------------------"

#List powered off VM's
$poweredoff=(get-vm | where-object {$_.powerstate -eq "PoweredOff"} |select name | out-string) -replace "`n", "`r`n"
Write-host "VM's that are powered off" `r`n
write-host $poweredoff | select name 

#Events for the last 24 hours
write-host "Events for the last 24 hours."
get-vievent -start (get-date).Addhours(-24) |select-object createdtime,username,fullformattedmessage
write-host "----------------------------------------------------------"

