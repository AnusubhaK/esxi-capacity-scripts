#This report will generate a small summary of the available ESXi Capacity
#the capacity is based simply on CPU and RAM commitment and does not mean that you can load up the host as each host 
#has a series of things to consider, the performance of each VM, CPU wait times, IOPS, etc. This script is merely a guide

clear-host
$debug_flag=0

#First step, what is the name of VCentre?
$name = Read-Host 'What vcenter server do you want to connect to?'
connect-viserver $name

#Now collect a list of all the ESXi hosts in VCentre
$esxi_hosts=get-vmhost |sort-object name

#Lets now get the date and time as a report really needs that
$timecode=get-date


#Clear the screen so it all looks nice and neat
clear

#Now we kick off the loop
ForEach ($esxi_host in $esxi_hosts) {
	if ($debug_flag -eq 1) {write-host "Checking " $esxi_host}
	#Grab a total of the number of CPU's allocated to each VM
	$vm_num_cpus=get-vm -location $esxi_host |measure-object -sum numcpu |fl sum |out-string
	
	$vm_num_cpus=$vm_num_cpus.trim()
	$vm_num_cpus=$vm_num_cpus.trim("Sum : ")
	#We now have the number of vCPU's
	
	[string]$phys_host_cpus=get-vmhost -name $esxi_host|fl numcpu |out-string
	[string]$phys_host_cpus=$phys_host_cpus.trim()
	[string]$phys_host_cpus=$phys_host_cpus.trim("NumCpu : ")
	#We now have the physical CPU's
	
	
	#Lets get everything into interger format
	[int]$max_vcpus=$phys_host_cpus
	$max_vcpus=$max_vcpus*5
	
	[int]$total_vcpus=$vm_num_cpus
	
	#This will gives us the total number of vCPU's that we can allocate and stay within VMWare/Dell best practice of 5:1 as a maximum
	
	$esxi_hostname=$esxi_host |fl name |out-string
	$esxi_hostname=$esxi_hostname.trim() |out-string
	$output=$esxi_hostname
	
	if ($debug_flag -eq 1) {write-host "total_vcpus " $total_vcpus}
	if ($debug_flag -eq 1) {write-host "max_vcpus " $max_vcpus}
	
	if ($total_vcpus -gt $max_vcpus) {$output +="There are too many vCPU's allocated to this host. There is no room for growth or new VM's" 
	$output +="`r`nThis host has "+$total_vcpus+ " vcpus allocated. The maximum it should have for 5:1 best practice is "+$max_vcpus
	}
	elseif ($total_vcpus -eq $max_vcpus) {$output +="This host is at 5:1 ratio for vCPU to pCPU and as such, is full."}
	else {$remaining_vcpu=$max_vcpus-$total_vcpus
	#$remaining_vcpu=$remaining_vcpu.trim()
	$output +="There are "+$remaining_vcpu+" vCPU's available to allocate to new or existing VM's before best practice limits of 5:1 are reached."}
	
	write-host $output
	
	$vm_sum_ram=get-vm -location $esxi_host |measure-object -sum memorygb |fl sum |out-string
	#trim out CR+LF and the Sum part of the output
	$vm_sum_ram=$vm_sum_ram.trim()
	$vm_sum_ram=$vm_sum_ram.trim("Sum : ")
	
	#Now get the RAM in the host
	$esxi_host_ram=get-vmhost $esxi_host |fl memorytotalgb |out-string
	#and to trim it
	$esxi_host_ram=$esxi_host_ram.trim()
	$esxi_host_ram=$esxi_host_ram.trim("MemoryTotalGB : ")
	
	$remaining_ram=[int]$esxi_host_ram-[int]$vm_sum_ram
	
	if ($remaining_ram -gt 0) {$output="This host has "+$remaining_ram+"GB RAM available for use by existing or new VM's"}
	elseif ($remaining_ram -eq 0) {$output="This host RAM is full. No more VM's can be added. Existing VM's CANNOT have RAM added"}
	else {$output="This host is overcommitted on RAM by "+($remaining_ram*-1)+"GB. It has "+([int]$vm_sum_ram)+"GB RAM allocated out of "+[int]$esxi_host_ram+"GB"}
	write-host $output
	write-host "NOTE: This report takes into account VM's that are both OFF and suspended. If the VM exists, it is included."
	write-host "----------------------------------------------------------"	
	write-host  `r`n `r`n
	
}

