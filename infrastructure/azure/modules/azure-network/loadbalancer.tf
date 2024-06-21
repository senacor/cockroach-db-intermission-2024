resource "azurerm_public_ip" "loadbalancer_ip" {
  name                = "ip-lb-cockroach"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_lb" "loadbalancer" {
  name                = "lb-cockroach"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.loadbalancer_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "cockroach_pool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "loadbalancer_ip"
}

/*
resource "azurerm_lb_backend_address_pool_address" "instance" {
  for_each                = { for node in var.nodes : node.name => node }
  name                    = each.key
  backend_address_pool_id = azurerm_lb_backend_address_pool.cockroach_pool.id
  virtual_network_id      = azurerm_virtual_network.virtual_network.id
  ip_address              = azurerm_network_interface.network_interface[each.key].private_ip_address
}
*/
