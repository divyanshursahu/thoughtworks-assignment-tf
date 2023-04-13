# Configuring the Microsoft Azure Provider

/* terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
} */

provider "azurerm" {
  features {}
}

#local variables used later in code
locals {
  private_key_path = "~/.ssh/id_rsa"
}

# Creating a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-ResourceGroup"
  location = "eastus"
}

# Creating virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
}

# Creating subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Creating public IPs
resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}-PublicIP"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

}

# Creating Network Security Group and rule & adding inbound port
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-NetworkSecurityGroup"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Port_80"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Creating network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-NIC"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Connecting the security group to the network interface
resource "azurerm_network_interface_security_group_association" "csgni" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Creating virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.prefix}-VM"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.prefix}-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  computer_name  = "${var.prefix}-myvm"
  admin_username = "azureuser"
  # admin_password                  = "Mediawiki1234!"
  disable_password_authentication = true


  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'wait unitll ssh is ready just for check'"
      # "sudo yum install epel-release yum-utils -y",
      # "sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm",
      # "sudo yum-config-manager --enable remi-php73",

    ]
    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file(local.private_key_path)
      host        = self.public_ip_address
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i azureuser@${self.public_ip_address}, --private-key ${local.private_key_path} main-playbook.yaml"
  }

}

# fetching public ip
data "azurerm_public_ip" "pubip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_linux_virtual_machine.vm.resource_group_name
}

# output of public ip
output "public_ip_address" {
  value = data.azurerm_public_ip.pubip.ip_address
}
