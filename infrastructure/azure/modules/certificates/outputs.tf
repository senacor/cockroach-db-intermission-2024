output "ca_certificate_pem" {
  value = tls_self_signed_cert.ca-certificate.cert_pem
}

output "node_keys" {
  value = { for key, result in tls_private_key.node-key : key => result.private_key_pem }
}

output "node_certificates" {
  value = { for key, result in tls_locally_signed_cert.node-cert : key => result.cert_pem }
}
