resource "azurerm_public_ip" "loadbalancer_ip" {
  name                = "ip-lb-cockroach"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "loadbalancer" {
  name                = "lb-cockroach"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku = "Standard"
  frontend_ip_configuration {
    name                 = "loadbalancer_ip"
    public_ip_address_id = azurerm_public_ip.loadbalancer_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "cockroach_pool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "cockroach_pool"
}

resource "azurerm_lb_backend_address_pool_address" "instance" {
  for_each                = { for node in var.nodes : node.name => node }
  name                    = each.key
  backend_address_pool_id = azurerm_lb_backend_address_pool.cockroach_pool.id
  virtual_network_id      = azurerm_virtual_network.virtual_network.id
  ip_address              = azurerm_network_interface.network_interface[each.key].private_ip_address
}

resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "cockroach-health"
  port            = 8080
  protocol        = "Http"
  request_path    = "/health?ready="
}

resource "azurerm_lb_rule" "ui_rule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "cockroach_admin_ui"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.health_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.cockroach_pool.id]
}

resource "azurerm_lb_rule" "db_rule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "cockroach_db"
  protocol                       = "Tcp"
  frontend_port                  = 26257
  backend_port                   = 26257
  frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.health_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.cockroach_pool.id]
}
