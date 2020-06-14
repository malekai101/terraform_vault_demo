output "vault_ip_addr" {
  value = aws_instance.vault.public_ip
}
output "vault_dns" {
  value = aws_instance.vault.public_dns
}
output "app_ip_addr" {
  value = aws_instance.application.public_ip
}
output "app_dns" {
  value = aws_instance.application.public_dns
}
output "db_endpoint" {
  value = aws_db_instance.football_db.endpoint
}

