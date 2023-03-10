resource "aws_apigatewayv2_api" "this" {
  name          = "${local.namespaced_service_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = local.lambdas

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.this[each.key].invoke_arn
}

resource "aws_apigatewayv2_route" "this" {
  for_each = {
    for file_path in local.lambdas : file_path => {
      route_key = "${upper(split(".", split("/", file_path)[length(split("/", file_path)) - 1])[0])} /${split("/", file_path)[0]}/${replace(replace(join("/", slice(split("/", file_path), 1, length(split("/", file_path)) - 1)), "__", "}"), "_", "{")}"
      target    = "integrations/${aws_apigatewayv2_integration.this[file_path].id}"
    }
  }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value["route_key"]
  target    = each.value["target"]
}
