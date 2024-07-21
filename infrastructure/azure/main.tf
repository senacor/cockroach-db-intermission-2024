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
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCuL0txPW8uhm0x+B+0AXnIWYPg+zNv0O4zEWFEHYWOyPEoTswyGBH66L6ieyQb6IXavQH3o5bcTPTW27TypeBg+BBO0TW6QsY3MOIsIHMSntmj/PP0elNqE0e5ATUoOhGAClViL5BvVJCKk1EaEbgnxdvTpBfYtSWJq/YJv3kneOGq08acoe6QupVFXZceBcz3bKcJ0Q9DCfvcol69l+KmO+FfPR3pw4zGDdgag7N1VmR076k2o4XTWFjT8BE3INE3u1soxYe7cf2bX4O9U418t5VNRrk1HDbnayPVlnFrx/H/3MnCaPu8UCttuKzbnQj3iFdR/0IQAyQm/w6cTNL3Ip7W/h4kb055hVgSzk3HwRS3b2SfGms1SWWVGJ7a9e6SdKsWpfF3YUyr+so5PwxXaN1cTeJRde7kiSluAdDiRt+t0n/B2kyyDdkUu17eCPhc6veTwV//H26RiHZkP/7Fy4IOLBYyhLVAbsEr+Jy02PGLm8iTfcQFaW3bPMW/P+xa1WivSAIGvqLXo2clUFS3U3VP98aJn7W9WNpQBq0tIju/wWa4T55W9O7YehbUEktFklcnGRj5psMUH2RL2BfU196PzFgfaAqZwGRjnoFUPji32JLYGTW/lFFBj/0KCV1FYPePwGdl3BuZNj5JEvwzIP6mceao46CYq+72kcd+uQ=="

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
  nodes2 = flatten([for _, result in module.azure-network : [
    for node in result.nodes : merge(node, {
      loadbalancer_ip = result.loadbalancer_ip
    })
    ]
  ])
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

data "cloudinit_config" "cockroachdb" {
  for_each      = { for node in local.nodes2 : node.name => node }
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = yamlencode({
      users = [
        "default",
        { name = "cockroach", ssh_authorized_keys = local.ssh_public_key }
      ],
      write_files = [
        {
          path        = "/var/lib/cockroach/certs/node.key"
          content     = module.certificates.node_keys[each.key]
          owner       = "cockroach:cockroach"
          permissions = "0600"
          defer       = true
        },
        {
          path        = "/var/lib/cockroach/certs/node.crt"
          content     = module.certificates.node_certificates[each.key]
          owner       = "cockroach:cockroach"
          permissions = "0600"
          defer       = true
        },
        {
          path        = "/var/lib/cockroach/certs/ca.crt"
          content     = module.certificates.ca_certificate_pem
          owner       = "cockroach:cockroach"
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
    username = "adminuser"
    # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfnEb7WAPrQSWhm1L9Kx0abiyGMXtfNI4aV+eBocJMq92h+k3HUkZvcY6u6v/VHqe+kzVl6EYq/O/49k4FwY3biaUxMDXQNd+B0MuWZHFqjDI60uiZqrhSaM++op/ZFP9xrS14I/qISxvS1ZqMuMuypPYg3Botsn69GVaw3+FPEvrWjb0o7et8H1oYKC28R19x/N/t8ZvMRZGwilHmpPuJY7aaIDTLEQ1z6lrYNgNuGRaWpWeQ6A388+OuwbxQXj8bx24IWLg8UfLEtaoztI9XWU+jKTmv3Kam814vuoLKnnrDRrLKeTT9oDK8MhVaOcf0bTAjzcJpXjZ6TLf2hePGTsfJFm0UPsVk/GCX5xcComi1E652nSx5/vwU06nfVh5ofrrlVciINDpzF8bl+clvUHq+y7O7LZvrRpFgzEvrpDDoIHePPdl070wUdSIKww8mc8+KasJBt0JY+yXQarIKcCQkuugvW8y1idTwHfV9FZXzeYbrsw2YyM67IW3xPOMeV8ft465Oxi2XKTj2KlqY6oDQWN/RIbstEegpqL8IDWzZb4zXs0pkNS5nMdVAJ0qDkfmWYWmJHQ00oGESi97iE8PQJCPkFa2JzD998OrS48xDigWG+AxvKQFIr5apcDV1XABMus0yBxd3cbRGL2nLnWqNOTMYe271DQxR+Tokjw=="
    public_key = local.ssh_public_key
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
