output "api_gateway_invoke_url" {
  description = "URL de invocação do API Gateway para a API de autenticação de CPF."
  value       = "${aws_api_gateway_deployment.cpf_auth_deployment.invoke_url}/${aws_api_gateway_resource.auth_resource.path_part}"
}

output "cognito_user_pool_id" {
  description = "ID do Cognito User Pool criado."
  value       = aws_cognito_user_pool.cpf_auth_pool.id
}

output "cognito_user_pool_client_id" {
  description = "ID do Cognito User Pool Client criado."
  value       = aws_cognito_user_pool_client.cpf_auth_client.id
}