provider "azurerm"{
    features{}
}

# Import Packer Image
data "azurerm_image" "main" {
    name = "project1-image"
    resource_group_name = "udacity-project1"
}

# Import the resource group where the VM will be created

data "azurerm_resource_group" "main" {
    name = "udacity-project1"
    location = "francecentral"
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags               = {
    environment = "project1"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main"{
    name = "${var.prefix}-nsg"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

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

    count = var.cluster_size

    name = "${var.prefix}-nic-${count.index}"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    network_security_group_id = azurerm_network_security_group.main.id
    ip_configuration {
        name = "${var.prefix}-ipconfig"
        subnet_id = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "project1"
    }
}

resource "azurerm_public_ip" "main" {
    name = "${var.prefix}-lb-public-ip"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    public_ip_address_allocation = "Static"
    public_ip_address_version = "IPv4"
    tags = {
        environment = "project1"
    }
}

resource "azurerm_lb" "main" {
    name = "${var.prefix}-lb"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    frontend_ip_configuration {
        name = "${var.prefix}-lb-frontend-ip"
        public_ip_address_id = azurerm_public_ip.main.id
    }
    tags = {
        environment = "project1"
    }
}

resource "azurerm_lb_backend_address_pool" "main" {
    name = "${var.prefix}-lb-backend-pool"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    loadbalancer_id = azurerm_lb.main.id
}
