terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
      version = "2.1.3"
    }
  }
}

## PROVIDER ##
provider "ncloud" {
  region      = var.region
  site        = var.site
  support_vpc = true
}

module "network" {
  source = "./modules/network"
}

## server ##
# ubuntu 서버 이미지 리스트 #
data "ncloud_server_images" "server_images" {
  # filter {
  #   name   = "product_name"
  #   values = ["ubuntu"]
  #   regex  = true
  # }
  output_file = "ubuntu_server_image_list.json"
}

data "ncloud_server_product" "product" {
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"
  filter {
    name   = "product_code"
    values = ["SSD"]
    regex  = true
  }
  filter {
    name   = "cpu_count"
    values = ["2"]
  }
  filter {
    name   = "memory_size"
    values = ["4GB"]
  }
  filter {
    name   = "product_type"
    values = ["HICPU"]
  }
}
output "product" {
  value = data.ncloud_server_product.product.product_code
}

## ACG ##
resource "ncloud_access_control_group" "acg" {
  name   = "pub-acg"
  vpc_no = module.network.vpc_id
}
## ACG Rule ##
resource "ncloud_access_control_group_rule" "acg-rule" {
  access_control_group_no = ncloud_access_control_group.acg.id
  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "22"
    description = "accept 22 port"
  }
}
## login key ##
resource "ncloud_login_key" "loginkey" {
  key_name = "blog-post-key"
}

## Server ##
resource "ncloud_server" "server" {
  subnet_no                 = module.network.pub_sub
  name                      = "post-server"
  server_product_code       = "SVR.VSVR.HICPU.C002.M004.NET.SSD.B050.G002"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"
  login_key_name            = ncloud_login_key.loginkey.key_name
}
