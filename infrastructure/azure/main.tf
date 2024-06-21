terraform {
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

locals {
  regions = {
    eu-west-azure = {
      provider      = "azure"
      nodes         = 3
      zones         = 3
      address_space = "10.0.1.0/24"
      location      = "West Europe"
    }
  }

  nodes = { for name, region in local.regions : name => [
    for index in range(region.nodes) : ({
      name     = "cockroach-${name}-${index}"
      region   = name
      zone     = index % region.zones
      provider = region.provider
    })
  ] }
}

module "azure-network" {
  for_each = { for name, region in local.regions : name => region if region.provider == "azure" }
  source   = "./modules/azure-network"

  name          = "cockroach-${each.key}"
  location      = each.value.location
  address_space = each.value.address_space
  nodes         = local.nodes[each.key]
}

locals {
  nodes2 = flatten([for _, result in module.azure-network : result.nodes])
}

output "nodes" {
  value = local.nodes2
}

module "certificates" {
  source = "./modules/certificates"

  nodes = local.nodes2
}

provider "azurerm" {
  features {}
}
provider "azuread" {
  tenant_id = "52497ec2-0945-4f55-8021-79766363dd96"
}

data "cloudinit_config" "cockroachdb" {
  for_each      = { for node in local.nodes2 : node.name => node }
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = yamlencode({
      write_files = [
        {
          path        = "/home/adminuser/certs/node.key"
          content     = module.certificates.node_keys[each.key]
          owner       = "adminuser:adminuser"
          permissions = "0600"
          defer       = true
        },
        {
          path        = "/home/adminuser/certs/node.crt"
          content     = module.certificates.node_certificates[each.key]
          owner       = "adminuser:adminuser"
          permissions = "0600"
          defer       = true
        },
        {
          path        = "/home/adminuser/certs/ca.crt"
          content     = module.certificates.ca_certificate_pem
          owner       = "adminuser:adminuser"
          permissions = "0600"
          defer       = true
        }
      ]
    })
  }
}

resource "azurerm_linux_virtual_machine" "cockroachdb-node" {
  for_each = { for node in local.nodes2 : node.name => node }

  name                = each.key
  resource_group_name = module.azure-network[each.value.region].resource_group_name
  location            = local.regions[each.value.region].location
  size                = "Standard_B1ms"

  admin_username = "adminuser"
  network_interface_ids = [
    each.value.nic_id
  ]
  custom_data = data.cloudinit_config.cockroachdb[each.key].rendered

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfnEb7WAPrQSWhm1L9Kx0abiyGMXtfNI4aV+eBocJMq92h+k3HUkZvcY6u6v/VHqe+kzVl6EYq/O/49k4FwY3biaUxMDXQNd+B0MuWZHFqjDI60uiZqrhSaM++op/ZFP9xrS14I/qISxvS1ZqMuMuypPYg3Botsn69GVaw3+FPEvrWjb0o7et8H1oYKC28R19x/N/t8ZvMRZGwilHmpPuJY7aaIDTLEQ1z6lrYNgNuGRaWpWeQ6A388+OuwbxQXj8bx24IWLg8UfLEtaoztI9XWU+jKTmv3Kam814vuoLKnnrDRrLKeTT9oDK8MhVaOcf0bTAjzcJpXjZ6TLf2hePGTsfJFm0UPsVk/GCX5xcComi1E652nSx5/vwU06nfVh5ofrrlVciINDpzF8bl+clvUHq+y7O7LZvrRpFgzEvrpDDoIHePPdl070wUdSIKww8mc8+KasJBt0JY+yXQarIKcCQkuugvW8y1idTwHfV9FZXzeYbrsw2YyM67IW3xPOMeV8ft465Oxi2XKTj2KlqY6oDQWN/RIbstEegpqL8IDWzZb4zXs0pkNS5nMdVAJ0qDkfmWYWmJHQ00oGESi97iE8PQJCPkFa2JzD998OrS48xDigWG+AxvKQFIr5apcDV1XABMus0yBxd3cbRGL2nLnWqNOTMYe271DQxR+Tokjw=="
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

resource "local_file" "ansible_inventory" {
  content = jsonencode({
    instances = {
      hosts = {
        for node in local.nodes2 : node.name => {
          ansible_host = node.public_ip
          ansible_user = "adminuser"
        }
      },
      vars = {
        cloud = "azure",
      }
    }
  })
  filename = "${path.root}/../../setup/inventory.json"
}

# cockroach sql --url='postgres://20.107.66.178:26257/?sslmode=verify-full&sslrootcert=infrastructure/azure/generated/ca.crt&sslcert=infrastructure/azure/generated/client.root.crt&sslkey=infrastructure/azure/generated/client.root.key&sslmode=verify-full'
# cockroach workload init tpcc 'postgres://root@20.107.66.178:26257/?sslmode=verify-full&sslrootcert=infrastructure/azure/generated/ca.crt&sslcert=infrastructure/azure/generated/client.root.crt&sslkey=infrastructure/azure/generated/client.root.key&sslmode=verify-full'
# cockroach init --url='postgres://root@51.144.250.129:26257/?sslmode=verify-full&sslrootcert=infrastructure/azure/generated/ca.crt&sslcert=infrastructure/azure/generated/client.root.crt&sslkey=infrastructure/azure/generated/client.root.key&sslmode=verify-full'
