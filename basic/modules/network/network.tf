terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
      version = "2.1.3"
    }
  }
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