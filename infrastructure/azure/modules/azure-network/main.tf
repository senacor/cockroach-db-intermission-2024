terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.name}"
  location = var.location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "virtual_network" {
  name                = "net-${var.name}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = [var.address_space]
}

resource "azurerm_network_security_group" "security_group" {
  name                = "sg-${var.name}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                   = "cockroach-admin"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "8080"
    // source_address_prefix      = "89.0.46.112"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "cockroach-app"
    priority               = 101
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "26257"
    // source_address_prefix      = "89.0.46.112"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "ssh-access"
    priority               = 102
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "22"
    // source_address_prefix      = "89.0.46.112"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "cockroach"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.address_space]
}

resource "azurerm_public_ip" "public_ip" {
  for_each            = { for node in var.nodes : node.name => node }
  name                = "ip-${each.key}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "network_interface" {
  for_each            = { for node in var.nodes : node.name => node }
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "nodes" {
  value = [for node in var.nodes : merge(node, {
    public_ip   = azurerm_public_ip.public_ip[node.name].ip_address
    internal_ip = azurerm_network_interface.network_interface[node.name].private_ip_address
    nic_id      = azurerm_network_interface.network_interface[node.name].id
  })]
}
