variable "hwcloud_region" { type = string }
variable "hwcloud_ak" { type = string }
variable "hwcloud_sk" { type = string }

provider "huaweicloud" {
  region     = var.hwcloud_region
  access_key = var.hwcloud_ak
  secret_key = var.hwcloud_sk
}

resource "huaweicloud_waf_cloud_instance" "my_cloud" {
  charging_mode         = "postPaid"
  website               = "hec-hk"
}

resource "huaweicloud_waf_policy" "test" {
  name                  = "policy-terraform"
  protection_mode       = "log"
  robot_action          = "block"
  level                 = 1

  options {
    crawler_scanner                = true
    crawler_script                 = true
    false_alarm_masking            = true
    general_check                  = true
    geolocation_access_control     = true
    information_leakage_prevention = true
    known_attack_source            = true
    precise_protection             = true
    web_tamper_protection          = true
    webshell                       = true
  }
    depends_on = [
    huaweicloud_waf_cloud_instance.my_cloud]
  # Make sure that a dedicated instance has been created.
}

#This rule block every traffic from all countries in your website
resource "huaweicloud_waf_rule_precise_protection" "precise_protection_block" {
  policy_id             = huaweicloud_waf_policy.test.id
  name                  = "rule_blocking-all-but-brazil"
  priority              = 10
  action                = "block"
  description           = "block all countries"
  status                = 1

  conditions {
    field   = "url"
    logic   = "contain"
    content = "/"
  }
}

#This rule allows only traffic in Brazil
resource "huaweicloud_waf_rule_geolocation_access_control" "test" {
  policy_id             = huaweicloud_waf_policy.test.id
  name                  = "allow-brazil"
  geolocation           = "BR"
  action                = 1
  description           = "allow brazil access to your website"
  
}

#If your site has HTTPS/SSL you can place your certificate here, otherwise, this resource is not necessary
resource "huaweicloud_waf_certificate" "certificate_1" {
  name                  = "cert_1"

#Replace here with our own certificate
  certificate = <<EOT
-----BEGIN CERTIFICATE-----
      ....
-----END CERTIFICATE-----
EOT
#Replace here
  private_key = <<EOT
-----BEGIN PRIVATE KEY-----
  ....
-----END PRIVATE KEY-----
EOT
}


resource "huaweicloud_waf_domain" "domain_1" {
  domain                = ".com.br" #Replace with your domain
  proxy                 = false
  charging_mode = "postPaid"
  protect_status = 1
  certificate_id = huaweicloud_waf_certificate.certificate_1.id
  certificate_name = huaweicloud_waf_certificate.certificate_1.name
  policy_id = huaweicloud_waf_policy.test.id

  server {
    client_protocol = "HTTP"
    server_protocol = "HTTP"
    address         = "..." # Replace here with your server/website IP
    port            = "80"
    type = "ipv4"

  }

  depends_on = [ huaweicloud_waf_cloud_instance.my_cloud ]
}
