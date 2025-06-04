# Provedor AWS
provider "aws" {
  region = var.aws_region
}

resource "aws_cognito_user_pool" "cpf_auth_pool" {
  name = "${var.project_name}-cpf-user-pool"

  username_attributes = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  auto_verified_attributes = []

  lifecycle {
    ignore_changes = [schema]
  }
}

resource "aws_cognito_user_pool_client" "cpf_auth_client" {
  name                = "${var.project_name}-app-client"
  user_pool_id        = aws_cognito_user_pool.cpf_auth_pool.id
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
  prevent_user_existence_errors = "LEGACY"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

resource "aws_lambda_function" "auth_customer_lambda" {
  function_name    = "${var.project_name}-auth-customer-lambda"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = var.labRole  # Usando a LabRole existente
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.cpf_auth_pool.id
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.cpf_auth_client.id
      DB_HOST     = "tc-fiap-postgres.comilucshvgd.us-east-1.rds.amazonaws.com"
      DB_USER     = "fiap_tc_user"
      DB_PASSWORD = "senha_dificil"
      DB_NAME     = "fiap_tc_db"
      DB_PORT     = "5432"
      DB_SSL      = "true"
    }
  }

  vpc_config {
    subnet_ids = [
        "subnet-0a36101a2f46d769d",
        "subnet-018805e1077cce9a0",
        "subnet-0345e872d9471041f",
        "subnet-01479a3659e677dbd",
        "subnet-097baaed34005a944",
    ]
    security_group_ids = [
      var.sg_eks_id
    ]
  }
}

resource "aws_api_gateway_rest_api" "cpf_auth_api" {
  name        = "${var.project_name}-cpf-auth-api"
  description = "API Gateway para autenticação de CPF com Lambda e Cognito"
}

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.cpf_auth_api.id
  parent_id   = aws_api_gateway_rest_api.cpf_auth_api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.cpf_auth_api.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cpf_auth_api.id
  resource_id = aws_api_gateway_resource.auth_resource.id
  http_method = aws_api_gateway_method.auth_post_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.auth_customer_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigateway_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_customer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.cpf_auth_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "cpf_auth_deployment" {
  rest_api_id = aws_api_gateway_rest_api.cpf_auth_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.auth_resource.id,
      aws_api_gateway_method.auth_post_method.id,
      aws_api_gateway_integration.auth_lambda_integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.cpf_auth_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.cpf_auth_api.id
  stage_name    = "prod"
}

import {
  to = aws_cognito_user_pool.cpf_auth_pool
  id = "us-east-1_5isSzg1fM"
}

import {
  to = aws_cognito_user_pool_client.cpf_auth_client
  id = "us-east-1_5isSzg1fM/6362pgp6c711o29pmjso7h4pii"
}

import {
  to = aws_lambda_function.auth_customer_lambda
  id = "fiap-tc-lambda-auth-customer-lambda"
}

import {
  to = aws_lambda_permission.apigateway_lambda_permission
  id = "fiap-tc-lambda-auth-customer-lambda/AllowAPIGatewayInvoke"
}