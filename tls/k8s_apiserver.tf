resource "tls_private_key" "apiserver_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "tls_cert_request" "apiserver_csr" {
  key_algorithm = "${tls_private_key.apiserver_key.algorithm}"
  private_key_pem = "${tls_private_key.apiserver_key.private_key_pem}"
  subject {
    common_name = "${var.tls_apiserver_cert_subject_common_name}"
  }

  ip_addresses = [
    "${ split(",", var.tls_apiserver_cert_ip_addresses) }"
  ]

  dns_names = [
    "${ split(",", var.tls_apiserver_cert_dns_names) }"
  ]
}

resource "tls_locally_signed_cert" "apiserver_cert" {
  cert_request_pem = "${tls_cert_request.apiserver_csr.cert_request_pem}"
  ca_key_algorithm = "${tls_private_key.ca_key.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca_key.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca_cert.cert_pem}"
  validity_period_hours = "${var.tls_apiserver_cert_validity_period_hours}"
  allowed_uses = [
    "key_encipherment",
    "server_auth",
    "client_auth",
    "cert_signing"
  ]
  early_renewal_hours = "${var.tls_apiserver_cert_early_renewal_hours}"
}

resource "null_resource" "apiserver-ssl" {

  provisioner "local-exec" {
    command = <<LOCAL_EXEC
echo "${tls_locally_signed_cert.apiserver_cert.cert_pem}" > apiserver.pem
echo "${tls_private_key.apiserver_key.private_key_pem}" > apiserver-key.pem
LOCAL_EXEC
  }
}


