# archiving lambda function definitions
data "archive_file" "placeChunkSetup_zip" {
    type = "zip"
    source_file = "placeChunkSetup.mjs"
    output_path = "placeChunkSetup.zip"
}

data "archive_file" "placeUpdateBoard_zip" {
    type = "zip"
    source_file = "placeUpdateBoard.mjs"
    output_path = "placeUpdateBoard.zip"
}

data "archive_file" "placeVerifySignup_zip" {
    type = "zip"
    source_file = "placeVerifySignup.mjs"
    output_path = "placeVerifySignup.zip"
}

# defining IAM roles
data "aws_iam_policy_document" "assume_role" {
    statement {
        effect = "Allow"
    
        principals {
        identifiers = ["lambda.amazonaws.com"]
        type        = "Service"
        }

        actions = ["sts:AssumeRole"]
    }
}

data "aws_iam_policy_document" "dynamodb_full_access" {
    statement {
        effect = "Allow"
        actions = [
            "dynamodb:*",
        ]
        resources = [
            "*",
        ]
    }
}


resource "aws_iam_policy" "dynamodb_full_access_policy" {
    name = "dynamodb_full_access_policy"
    policy = data.aws_iam_policy_document.dynamodb_full_access.json
}

resource "aws_iam_role" "lambda_dynamodb_iam_role" {
    name = "lambda_dynamodb_iam_role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "lambda_basic_iam_role" {
    name = "lambda_basic_iam_role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access_policy_attachment" {
    role = aws_iam_role.lambda_dynamodb_iam_role.name
    policy_arn = aws_iam_policy.dynamodb_full_access_policy.arn
}

# provisioning lambda resources
resource "aws_lambda_function" "placeChunkSetup" {
    filename = data.archive_file.placeChunkSetup_zip.output_path
    function_name = "placeChunkSetup"
    role = aws_iam_role.lambda_dynamodb_iam_role.arn
    handler = "placeChunkSetup.handler"
    runtime = "nodejs18.x"
    source_code_hash = data.archive_file.placeChunkSetup_zip.output_base64sha256
    memory_size = "256"
    timeout = "10"
}

resource "aws_lambda_function" "placeUpdateBoard" {
    filename = data.archive_file.placeUpdateBoard_zip.output_path
    function_name = "placeUpdateBoard"
    role = aws_iam_role.lambda_dynamodb_iam_role.arn
    handler = "placeUpdateBoard.handler"
    runtime = "nodejs18.x"
    source_code_hash = data.archive_file.placeUpdateBoard_zip.output_base64sha256
}

resource "aws_lambda_function" "placeVerifySignup" {
    filename = data.archive_file.placeVerifySignup_zip.output_path
    function_name = "placeVerifySignup"
    role = aws_iam_role.lambda_basic_iam_role.arn
    handler = "placeVerifySignup.handler"
    runtime = "nodejs18.x"
    source_code_hash = data.archive_file.placeVerifySignup_zip.output_base64sha256
}

