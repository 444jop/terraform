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
resource "ncloud_vpc" "fe" {
  name            = "fe-vpc"
  ipv4_cidr_block = "10.0.0.0/16"
}

resource "ncloud_vpc" "be" {
  name            = "be-vpc"
  ipv4_cidr_block = "10.1.0.0/16"
}

resource "ncloud_vpc" "mgmt" {
  name            = "mgmt-vpc"
  ipv4_cidr_block = "10.2.0.0/16"
}

## NACL ##
resource "ncloud_network_acl" "pubsub" {
  vpc_no = ncloud_vpc.fe.id
  name   = "fe-pub-subnet-nacl"
}

resource "ncloud_network_acl" "prisub" {
  vpc_no = ncloud_vpc.be.id
  name   = "be-pri-subnet-nacl"

}
resource "ncloud_network_acl" "prisub2" {
  vpc_no = ncloud_vpc.mgmt.id
  name   = "mgmt-pri-subnet-nacl"
}

## NACL Rule ##
resource "ncloud_network_acl_rule" "pubsub" {
  network_acl_no = ncloud_network_acl.pubsub.id
}

resource "ncloud_network_acl_rule" "prisub" {
  network_acl_no = ncloud_network_acl.prisub.id
}

resource "ncloud_network_acl_rule" "prisub2" {
  network_acl_no = ncloud_network_acl.prisub2.id
}

## Subnet ##
resource "ncloud_subnet" "pubsub" {
  vpc_no         = ncloud_vpc.fe.id
  subnet         = "10.0.0.0/16"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.pubsub.id
  subnet_type    = "PUBLIC"
  name           = "pub-subnet"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "prisub" {
  vpc_no         = ncloud_vpc.be.id
  subnet         = "10.1.0.0/16"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.prisub.id
  subnet_type    = "PRIVATE"
  name           = "pri-subnet"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "prisub2" {
  vpc_no         = ncloud_vpc.mgmt.id
  subnet         = "10.2.0.0/16"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.prisub2.id
  subnet_type    = "PRIVATE"
  name           = "pri2-subnet"
  usage_type     = "GEN"
}
## route table ##
resource "ncloud_route_table" "fe_pub_rt" {
  vpc_no = ncloud_vpc.fe.id
  supported_subnet_type = "PUBLIC"
  name = "fe-pub-rt"
}
resource "ncloud_route_table" "be_pri_rt" {
  vpc_no = ncloud_vpc.be.id
  supported_subnet_type = "PRIVATE"
  name = "be-pri-rt" 
}
resource "ncloud_route_table" "mgmt_pri_rt" {
  vpc_no = ncloud_vpc.mgmt.id
  supported_subnet_type = "PRIVATE"
  name = "mgmt-pri-rt"
}

## route table - subnet association ##
resource "ncloud_route_table_association" "fe_rt_sub" {
  route_table_no = ncloud_route_table.fe_pub_rt.id
  subnet_no = ncloud_subnet.pubsub.id  
}

resource "ncloud_route_table_association" "be_rt_sub" {
  route_table_no = ncloud_route_table.be_pri_rt.id
  subnet_no = ncloud_subnet.prisub.id
}

resource "ncloud_route_table_association" "mgmt_rt_sub" {
  route_table_no = ncloud_route_table.mgmt_pri_rt.id
  subnet_no = ncloud_subnet.prisub2.id
}

## NAT Gateway ##
resource "ncloud_nat_gateway" "nat_gateway" {
  vpc_no = ncloud_vpc.be.id
  zone   = "KR-2"
  name   = "nat-gw"
}

## Route ##
resource "ncloud_route" "natroute" {
  route_table_no = ncloud_route_table.be_pri_rt.id
  destination_cidr_block = "0.0.0.0/0"
  target_type = "NATGW"
  target_name = ncloud_nat_gateway.nat_gateway.name
  target_no = ncloud_nat_gateway.nat_gateway.id
}

## vpc peering 라우팅 필요
resource "ncloud_route" "peering_route" {
  route_table_no = ncloud_route_table.fe_pub_rt.id
  destination_cidr_block = "10.1.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering.name
  target_no = ncloud_vpc_peering.peering.id
}

resource "ncloud_route" "peering2_route" {
  route_table_no = ncloud_route_table.be_pri_rt.id
  destination_cidr_block = "10.0.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering2.name
  target_no = ncloud_vpc_peering.peering2.id
}
resource "ncloud_route" "peering3_route" {
  route_table_no = ncloud_route_table.be_pri_rt.id
  destination_cidr_block = "10.2.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering3.name
  target_no = ncloud_vpc_peering.peering3.id
}

resource "ncloud_route" "peering4_route" {
  route_table_no = ncloud_route_table.mgmt_pri_rt.id
  destination_cidr_block = "10.1.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering4.name
  target_no = ncloud_vpc_peering.peering4.id
}

resource "ncloud_route" "peering5_route" {
  route_table_no = ncloud_route_table.fe_pub_rt.id
  destination_cidr_block = "10.2.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering5.name
  target_no = ncloud_vpc_peering.peering5.id
}

resource "ncloud_route" "peering6_route" {
  route_table_no = ncloud_route_table.mgmt_pri_rt.id
  destination_cidr_block = "10.0.0.0/16"
  target_type = "VPCPEERING"
  target_name = ncloud_vpc_peering.peering6.name
  target_no = ncloud_vpc_peering.peering6.id
}

## VPC Peering ##
resource "ncloud_vpc_peering" "peering" {
  name          = "vpc-peering"
  source_vpc_no = ncloud_vpc.fe.id
  target_vpc_no = ncloud_vpc.be.id
}
resource "ncloud_vpc_peering" "peering2" {
  name          = "vpc-peering2"
  source_vpc_no = ncloud_vpc.be.id
  target_vpc_no = ncloud_vpc.fe.id
}
resource "ncloud_vpc_peering" "peering3" {
  name          = "vpc-peering3"
  source_vpc_no = ncloud_vpc.be.id
  target_vpc_no = ncloud_vpc.mgmt.id
}
resource "ncloud_vpc_peering" "peering4" {
  name          = "vpc-peering4"
  source_vpc_no = ncloud_vpc.mgmt.id
  target_vpc_no = ncloud_vpc.be.id
}
resource "ncloud_vpc_peering" "peering5" {
  name          = "vpc-peering5"
  source_vpc_no = ncloud_vpc.fe.id
  target_vpc_no = ncloud_vpc.mgmt.id
}
resource "ncloud_vpc_peering" "peering6" {
  name          = "vpc-peering6"
  source_vpc_no = ncloud_vpc.mgmt.id
  target_vpc_no = ncloud_vpc.fe.id
}

## server ##
# ubuntu 서버 이미지 리스트 #
data "ncloud_server_images" "server_images" {
    filter {
      name = "product_name"
      values = ["ubuntu"]
      regex = true
    }
  output_file = "ubuntu_server_image_list.json"
}

data "ncloud_server_product" "product"{
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
  name        = "pub-acg"
  vpc_no      = ncloud_vpc.fe.id
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
  server_product_code = "SVR.VSVR.HICPU.C002.M004.NET.SSD.B050.G002"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"
  login_key_name            = ncloud_login_key.loginkey.key_name
}
