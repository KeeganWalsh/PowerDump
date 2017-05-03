PARAM(
        [Parameter(Mandatory=$FALSE,HelpMessage="VM Name")][string]$VMName,
        [Parameter(Mandatory=$FALSE,HelpMessage="VM Tag")][hashtable]$Tags
      )

#HardCoded Paths/Values
Select-AzureRmProfile -Path "C:\Hidden\VSAccount.json" | Out-Null
$Template = Get-Content "C:\PowerDump\Azure\Templates\CattleDomain.json" | convertFrom-Json
$secpasswd = ConvertTo-SecureString “Adminadmin1!” -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential (“admin123”, $secpasswd)

#Build Resource Group if it doesn't exist
TRY{
    $RG = Get-AzureRmResourceGroup `
            -Name $Template.ResourceGroup.Name `
            -Location $Template.ResourceGroup.Location `
            -ErrorAction Stop
}CATCH{
    $RG = New-AzureRmResourceGroup `
            -Name $Template.ResourceGroup.Name `
            -Location $Template.ResourceGroup.Location
}

#Create Resource Group V-Net if it doesn't exist
TRY{
    $VNet = Get-AzureRmVirtualNetwork `
                -ResourceGroupName $Template.ResourceGroup.Name `
                -Name $Template.Vnet.Name `
                -ErrorAction Stop
}CATCH{
     $VNet = New-AzureRmVirtualNetwork `
        -ResourceGroupName $Template.ResourceGroup.Name `
        -Name $Template.Vnet.Name `
        -AddressPrefix $Template.Vnet.AddressPrefix `
        -Location $Template.ResourceGroup.Location
}

#Add Subnet to VNet if it doesn't already exist
TRY{
    TRY{
        Get-AzureRmVirtualNetworkSubnetConfig -Name $Template.Vnet.Subnet.Name -VirtualNetwork $VNet -ErrorAction Stop
    }CATCH{
        $Subnet = Add-AzureRmVirtualNetworkSubnetConfig `
                    -Name $Template.Vnet.Subnet.Name `
                    -VirtualNetwork $VNet `
                    -AddressPrefix $Template.Vnet.Subnet.AddressPrefix `
                    -ErrorAction Stop
        Set-AzureRmVirtualNetwork -VirtualNetwork $VNet -ErrorAction Stop
    }
}CATCH{
     Write-Output "COULD NOT CREATE SUBNET - $($Template.Vnet.Subnet.Name)"
     $Error[0]
}

#Create Resource Group NSG if it doesn't exist
TRY{
    TRY{
        $NSG = Get-AzureRmNetworkSecurityGroup -Name $Template.NetworkSecurityGroup.Name -ResourceGroupName $Template.ResourceGroup.Name -ErrorAction Stop
    }CATCH{
        $NSG = New-AzureRmNetworkSecurityGroup `
                -ResourceGroupName $Template.ResourceGroup.Name `
                -Location $Template.ResourceGroup.Location `
                -Name $Template.NetworkSecurityGroup.Name 
    }
    FOREACH($Rule IN $Template.NetworkSecurityGroup.Rules){
        TRY{
            Get-AzureRmNetworkSecurityRuleConfig -Name $Rule.Name -NetworkSecurityGroup $NSG -ErrorAction Stop
        }CATCH{
            $NSG | Add-AzureRmNetworkSecurityRuleConfig `
                    -Name $Rule.Name `
                    -Priority $Rule.Properties.priority `
                    -SourceAddressPrefix $Rule.Properties.sourceAddressPrefix `
                    -Protocol $Rule.Properties.protocol `
                    -DestinationPortRange $Rule.Properties.DestinationPortRange `
                    -Access $Rule.Properties.Access `
                    -Direction $Rule.Properties.Direction `
                    -SourcePortRange $Rule.Properties.SourcePortRange `
                    -DestinationAddressPrefix $Rule.Properties.DestinationAddressPrefix
            $NSG | Set-AzureRmNetworkSecurityGroup 
        }
    }
}CATCH{
     Write-Output "COULD NOT CREATE NSG - $($Template.NetworkSecurityGroup.Name)"
     $Error[0]
}

#Save VNet Settings
Set-AzureRmVirtualNetwork -VirtualNetwork $VNet
#Get New VNet Info
$VNet = Get-AzureRmVirtualNetwork -Name $Template.Vnet.Name -ResourceGroupName $Template.ResourceGroup.Name

#If No VM Name parameter sent to script, generate random name
IF(!($VMName)){
    $VMName = [guid]::NewGuid().ToString().Replace("-","").Substring(0,10).ToLower()
    #If by some act of god you manage to get a GUID that already exists, get a new one
    TRY{
        IF(Get-AzureRMVM -ResourceGroupName $Template.ResourceGroup.Name -Name $VMName -ErrorAction Stop){
            $VMName = [guid]::NewGuid().ToString().Replace("-","").Substring(0,10).ToLower()
        }
    }CATCH{}
}

#Create Disk Storage
$DiskStorage = New-AzureRmStorageAccount `
                -ResourceGroupName $Template.ResourceGroup.Name `
                -Name "$($VMName)disk" `
                -SkuName Premium_LRS `
                -Location $Template.ResourceGroup.Location

#Create Diagnostic Storage
$DaigStorage = New-AzureRmStorageAccount `
                -ResourceGroupName $Template.ResourceGroup.Name `
                -Name "$($VMName)diag" `
                -SkuName Standard_LRS `
                -Location $Template.ResourceGroup.Location

#Create New Public IP
New-AzureRmPublicIpAddress `
    -Name "$VMName-IP" `
    -ResourceGroupName $Template.ResourceGroup.Name `
    -Location $Template.ResourceGroup.Location `
    -AllocationMethod Dynamic
 
#Build NIC Config
$PublicIP = Get-AzureRmPublicIpAddress -Name "$VMName-IP" -ResourceGroupName $Template.ResourceGroup.Name
$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $Template.VNet.Subnet.Name -VirtualNetwork $VNet
$NICConfig = New-AzureRmNetworkInterfaceIpConfig `
                -Name "$VMName-NICConfig" `
                -PublicIpAddress $PublicIP `
                -Subnet $Subnet
#Create NIC
$NIC = New-AzureRmNetworkInterface `
    -Name "$VMName-NIC" `
    -ResourceGroupName $Template.ResourceGroup.Name `
    -Location $Template.ResourceGroup.Location `
    -IpConfiguration $NICConfig 

## Setup local VM object

$VirtualMachine = New-AzureRmVMConfig `
                    -VMName $VMName `
                    -VMSize $Template.VMTemplate.Size
$VirtualMachine = Set-AzureRmVMOperatingSystem `
                    -VM $VirtualMachine `
                    -ComputerName $VMName `
                    -Credential $Credential `
                    -Windows `
                    -ProvisionVMAgent `
                    -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage `
                    -VM $VirtualMachine `
                    -PublisherName $Template.VMTemplate.Publisher `
                    -Offer $Template.VMTemplate.Offer `
                    -Skus $Template.VMTemplate.Sku `
                    -Version $Template.VMTemplate.Version
$VirtualMachine = Add-AzureRmVMNetworkInterface `
                    -VM $VirtualMachine `
                    -Id $NIC.Id
$VirtualMachine = Set-AzureRmVMOSDisk `
                    -VM $VirtualMachine `
                    -Name $DiskStorage.StorageAccountName `
                    -VhdUri "$($DiskStorage.PrimaryEndpoints.Blob.ToString())vhds/$($DiskStorage.StorageAccountName).vhd" `
                    -CreateOption $Template.VMTemplate.CreateOption                    

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $Template.ResourceGroup.Name -Location $Template.ResourceGroup.Location -VM $VirtualMachine

IF($Tags){
    $Resource = Get-AzureRmResource -ResourceName $VMName -ResourceGroupName $Template.ResourceGroup.Name
    $CurrentTags = $Resource.Tags
    $CurrentTags += $Tags
    Set-AzureRmResource -Tag $CurrentTags -ResourceName $Resource.Name -ResourceGroupName $Resource.ResourceGroupName -ResourceType $Resource.ResourceType -Force
}

TRY{
    $VM = Get-AzureRMVM -ResourceGroupName $Template.ResourceGroup.Name -Name $VMName -ErrorAction Stop
    Write-Output "$($VM.Name) Ready For Use"
}CATCH{
    Write-Output "AW SNAP, Something Went Wrong! There Doesn't Appear To Be A VM Here"
}