provider "azurerm"{
    features{}
}

/* resource "azurerm_resource_group" "main" {
    name         = "${var.prefix}"
    location     = "${var.location}"
} */

data "azurerm_resource_group" "main" {
  name = var.resource-group
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags                = {
    environment = "project1"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main"{
    name                            = "${var.prefix}-nsg"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name

    security_rule {
        name                        = "Allow_local_access"
        description                 = "Allow virtual machine access within the subnet"
        protocol                    = "*"
        priority                    =  100
        access                      = "Allow"
        direction                   = "Inbound"
        source_port_range           = "*"
        destination_port_range      = "*"
        source_address_prefix       = "VirtualNetwork"
        destination_address_prefix  = "VirtualNetwork"
    }

    security_rule {
        name                        = "Deny_inbound_from_Internet"
        description                 = "Deny inbound traffic from the Internet"
        protocol                    = "*"
        priority                    =  200
        access                      = "Deny"
        direction                   = "Inbound"
        source_port_range           = "*"
        destination_port_range      = "*"
        source_address_prefix       = "Internet"
        destination_address_prefix  = "VirtualNetwork"

    }

    tags = {
        environment = "project1"

    }
}

resource "azurerm_network_interface" "main" {

    count = var.vms-count > 5 ? 5 : var.vms-count

    name                            = "${var.prefix}-nic-${count.index}"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    
    ip_configuration {
        name                        = "nic-ip-config"
        subnet_id                   = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "project1"
    }
}

resource "azurerm_public_ip" "main" {
    name                            = "${var.prefix}-lb-public-ip"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    allocation_method               = "Static"
    
    tags = {
        environment = "project1"
    }
}

resource "azurerm_lb" "main" {
    name                            = "${var.prefix}-lb"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    
    frontend_ip_configuration {
        name                        = "${var.prefix}-lb-public-ip"
        public_ip_address_id        = azurerm_public_ip.main.id
    }

    tags = {
        environment = "project1"
    }
}

resource "azurerm_lb_backend_address_pool" "main" {

    name                            = "${var.prefix}-lb-backend-pool"
    loadbalancer_id                 = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
    
    count   = var.vms-count > 5 ? 5 : var.vms-count

    network_interface_id            = azurerm_network_interface.main[count.index].id
    ip_configuration_name           = "nic-ip-config"
    backend_address_pool_id         = azurerm_lb_backend_address_pool.main.id
}


resource "azurerm_availability_set" "main" {
    name                            = "${var.prefix}-avail-set"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    platform_update_domain_count    = 5
    platform_fault_domain_count     = 2
}


# Import Packer Image
data "azurerm_image" "main" {
    name                = "project1-image"
    resource_group_name = var.resource-group
}

resource "azurerm_linux_virtual_machine" "main"{

    count   = var.vms-count > 5 ? 5 : var.vms-count   # number of VMs to create and assuring the count stays below 5
    name                            = "${var.prefix}-vm-${count.index}"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    size                            = "Standard_B2s"
    availability_set_id             = azurerm_availability_set.main.id
    network_interface_ids           = [azurerm_network_interface.main[count.index].id]
    admin_username                  = var.username
    admin_password                  = var.password
    disable_password_authentication = false
    source_image_id                 = data.azurerm_image.main.id

    os_disk {
        name                    = "${var.prefix}-vm-${count.index}-disk"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }


    tags = {
        environment = "project1"
    }
}

resource "azurerm_managed_disk" "main" {
    name                            = "${var.prefix}-managed-disk"
    location                        = data.azurerm_resource_group.main.location
    resource_group_name             = data.azurerm_resource_group.main.name
    storage_account_type            = "Standard_LRS"
    create_option                   = "Empty"
    disk_size_gb                    = "5"

    tags = {
        environment = "project1"
    }
}