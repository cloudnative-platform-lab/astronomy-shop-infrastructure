output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "database_subnet_ids" { value = aws_subnet.database[*].id }
output "database_subnet_group_name" { value = aws_db_subnet_group.this.name }
output "flow_log_id" { value = try(aws_flow_log.this[0].id, null) }
output "interface_endpoint_ids" { value = { for service, endpoint in aws_vpc_endpoint.interface : service => endpoint.id } }
