output "vault_ip_addr" {
  value = aws_eip.vault.public_ip
}
output "vault_dns" {
  value = aws_eip.vault.public_dns
}
output "app_ip_addr" {
  value = aws_eip.application.public_ip
}
output "app_dns" {
  value = aws_eip.application.public_dns
}
output "db_endpoint" {
  value = aws_db_instance.football_db.endpoint
}

