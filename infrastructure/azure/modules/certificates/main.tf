terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

variable "nodes" {
  type = list(object({
    name        = string
    public_ip   = string
    internal_ip = string
  }))
}

resource "tls_private_key" "ca-private-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca-certificate" {
  private_key_pem = tls_private_key.ca-private-key.private_key_pem

  subject {
    common_name  = "Cockroach CA"
    organization = "Cockroach"
  }

  is_ca_certificate     = true
  validity_period_hours = 365 * 24

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing"
  ]
}

resource "local_file" "ca-cert" {
  content  = tls_self_signed_cert.ca-certificate.cert_pem
  filename = "${path.root}/generated/ca.crt"
}

resource "tls_private_key" "node-key" {
  for_each  = { for node in var.nodes : node.name => node }
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "node-cert-request" {
  for_each        = { for node in var.nodes : node.name => node }
  private_key_pem = tls_private_key.node-key[each.key].private_key_pem

  subject {
    common_name  = "Cockroach CA"
    organization = "Cockroach"
  }
  dns_names    = ["node", "localhost", "cockroach-db-load-balancer-91272505df4b8aa8.elb.eu-central-1.amazonaws.com"]
  ip_addresses = [each.value.public_ip, each.value.internal_ip, "127.0.0.1"]
}

resource "tls_locally_signed_cert" "node-cert" {
  for_each           = { for node in var.nodes : node.name => node }
  cert_request_pem   = tls_cert_request.node-cert-request[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.ca-private-key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca-certificate.cert_pem

  validity_period_hours = 365 * 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "local_sensitive_file" "node-key" {
  for_each = { for node in var.nodes : node.name => node }
  content  = tls_private_key.node-key[each.key].private_key_pem
  filename = "${path.root}/generated/node.${each.key}.key"
}

resource "local_file" "node-cert" {
  for_each = { for node in var.nodes : node.name => node }
  content  = tls_locally_signed_cert.node-cert[each.key].cert_pem
  filename = "${path.root}/generated/node.${each.key}.crt"
}

resource "tls_private_key" "user-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "user-cert-request" {
  private_key_pem = tls_private_key.user-key.private_key_pem

  subject {
    common_name  = "root"
    organization = "Cockroach"
  }
  dns_names = ["root"]
}

resource "tls_locally_signed_cert" "user-cert" {
  cert_request_pem   = tls_cert_request.user-cert-request.cert_request_pem
  ca_private_key_pem = tls_private_key.ca-private-key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca-certificate.cert_pem

  validity_period_hours = 365 * 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "local_sensitive_file" "user-key" {
  content  = tls_private_key.user-key.private_key_pem
  filename = "${path.root}/generated/client.root.key"
}

resource "local_file" "user-cert" {
  content  = tls_locally_signed_cert.user-cert.cert_pem
  filename = "${path.root}/generated/client.root.crt"
}
