output "vpc_id" {
    value = ncloud_vpc.vpc.id
}
output "pub_sub" {
    value = ncloud_subnet.pub-sub.id
}