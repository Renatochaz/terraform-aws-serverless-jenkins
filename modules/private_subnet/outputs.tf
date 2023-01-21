output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "ID of the private subnet"
}