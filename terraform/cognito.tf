resource "aws_cognito_user_pool" "pool" {
    name = "placeUserPool"

    username_attributes = ["email"]

    password_policy {
      minimum_length = 8
      require_lowercase = false
      require_numbers = false
      require_symbols = false
      require_uppercase = false
    }

    lambda_config {
        pre_sign_up = aws_lambda_function.placeVerifySignup.arn
    }
}

# permission to trigger pre sign up lambda function
resource "aws_lambda_permission" "cognitoLambdaInvokePermission" {
    statement_id = "cognitoLambdaInvokePermission"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.placeVerifySignup.function_name
    principal = "cognito-idp.amazonaws.com"
    source_arn = aws_cognito_user_pool.pool.arn
}

# creating application client
resource "aws_cognito_user_pool_client" "cognitoClient" {
    name = "cognitoClient"
    user_pool_id = aws_cognito_user_pool.pool.id
}