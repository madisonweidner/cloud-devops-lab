# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "Cloud-Eng-Lab"
  location = "eastus"
}

resource "azurerm_network_security_group" "nsg" {
name = "MyNSG"
location = "eastus"
resource_group_name = "Cloud-Eng-Lab"

security_rule {
  name = "allow_tcp_outbound"
  priority = 100
  access = "Allow"
  direction = "outbound"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix  = "*"
  destination_address_prefix = "*"
}
}
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "my_subnet" {
name                  = "MySubnet"
resource_group_name = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.vnet.name
address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
name = "mynic"
location = "eastus"
resource_group_name = azurerm_resource_group.rg.name

ip_configuration {
name = "internal"
subnet_id = azurerm_subnet.my_subnet.id
private_ip_address_allocation = "Dynamic"
}
}
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "cloud_eng_lab_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
}

#Create an Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
name = "UbuntuMachine"
resource_group_name = azurerm_resource_group.rg.name
location = "eastus"
size = "Standard_F2"
admin_username = "admin"
network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "admin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
