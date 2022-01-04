terraform {
  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
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


## NETWORKING ##
## VPC ##
resource "ncloud_vpc" "vpc" {
  name            = "basic-vpc"
  ipv4_cidr_block = "10.0.0.0/16"
}

## NACL ##
resource "ncloud_network_acl" "pub-sub" {
  vpc_no = ncloud_vpc.vpc.id
  name   = "pub-subnet-nacl"
}

resource "ncloud_network_acl" "pri-sub" {
  vpc_no = ncloud_vpc.vpc.id
  name   = "pri-subnet-nacl"
}

## NACL Rule ##
resource "ncloud_network_acl_rule" "pub-sub" {
  network_acl_no = ncloud_network_acl.pub-sub.id
}

resource "ncloud_network_acl_rule" "pri-sub" {
  network_acl_no = ncloud_network_acl.pri-sub.id
}

## Subnet ##
resource "ncloud_subnet" "pub-sub" {
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.0.0.0/16"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.pub-sub.id
  subnet_type    = "PUBLIC"
  name           = "pub-subnet"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "pri-sub" {
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.1.0.0/16"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.pri-sub.id
  subnet_type    = "PRIVATE"
  name           = "pri-subnet"
  usage_type     = "GEN"
}

## route table ##
resource "ncloud_route_table" "pub-rt" {
  vpc_no                = ncloud_vpc.vpc.id
  supported_subnet_type = "PUBLIC"
  name                  = "pub-rt"
}
resource "ncloud_route_table" "pri-rt" {
  vpc_no                = ncloud_vpc.vpc.id
  supported_subnet_type = "PRIVATE"
  name                  = "pri-rt"
}

## route table - subnet association ##
resource "ncloud_route_table_association" "pub-sub-rt-ass" {
  route_table_no = ncloud_route_table.pub-rt.id
  subnet_no      = ncloud_subnet.pub-sub.id
}

resource "ncloud_route_table_association" "pri-sub-rt-ass" {
  route_table_no = ncloud_route_table.pri-rt.id
  subnet_no      = ncloud_subnet.pri-sub.id
}

## NAT Gateway ##
resource "ncloud_nat_gateway" "nat_gateway" {
  vpc_no = ncloud_vpc.vpc.id
  zone   = "KR-2"
  name   = "nat-gw"
}

## Route ##
resource "ncloud_route" "natroute" {
  route_table_no         = ncloud_route_table.pri-rt.id
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = ncloud_nat_gateway.nat_gateway.name
  target_no              = ncloud_nat_gateway.nat_gateway.id
}
## server ##
# ubuntu 서버 이미지 리스트 #
data "ncloud_server_images" "server_images" {
  filter {
    name   = "product_name"
    values = ["ubuntu"]
    regex  = true
  }
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
  vpc_no = ncloud_vpc.fe.id
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
  subnet_no                 = ncloud_subnet.pubsub.id
  name                      = "post-server"
  server_product_code       = "SVR.VSVR.HICPU.C002.M004.NET.SSD.B050.G002"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"
  login_key_name            = ncloud_login_key.loginkey.key_name
}
