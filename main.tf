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

## NAT Gateway ##
resource "ncloud_nat_gateway" "nat_gateway" {
  vpc_no = ncloud_vpc.be.id
  zone   = "KR-2"
  name   = "nat-gw"
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