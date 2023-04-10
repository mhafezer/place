# Provisioning appsync and defining schema
resource "aws_appsync_graphql_api" "appsync" {
    authentication_type = "API_KEY"
    name = "placeAppSync"

    additional_authentication_provider {
        authentication_type = "AMAZON_COGNITO_USER_POOLS"
        user_pool_config {
            user_pool_id = aws_cognito_user_pool.pool.id
        }
    }

    schema = <<EOF
    schema {
        query: Query
        mutation: Mutation
        subscription: Subscription
    }
    type Query {
        getPlaceChunks(c: String!): PlaceChunks
    }
    type PlaceChunks {
        c: String!
        v: [String]
    }
    type Mutation @aws_cognito_user_pools {
	    updateBoard(x: Int!, y: Int!, color: Int!): pixel!
    }
    type Subscription {
	    updatedPixel: pixel
		    @aws_subscribe(mutations: ["updateBoard"])
    }
    type pixel @aws_cognito_user_pools
    @aws_api_key {
        x: String!
        y: String!
        color: String!
    }
    EOF
}

# creating API KEY
resource "aws_appsync_api_key" "key" {
    api_id = aws_appsync_graphql_api.appsync.id
    expires = "2024-04-01T04:00:00Z"
}

# assume role for appsync
data "aws_iam_policy_document" "appsync_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# creating DynamoDB datasource
data "aws_iam_policy_document" "dyanamo_db_appsync_policy_document" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:*"]
        resources = [aws_dynamodb_table.placeChunks.arn]
    }
}

resource "aws_iam_role" "dynamo_db_datasource_role" {
    name = "dynamo_db_datasource_role"
    assume_role_policy = data.aws_iam_policy_document.appsync_assume_role.json
}

resource "aws_iam_role_policy" "dyanamo_db_appsync_policy" {
    name = "dyanamo_db_appsync_policy"
    role = aws_iam_role.dynamo_db_datasource_role.id
    policy = data.aws_iam_policy_document.dyanamo_db_appsync_policy_document.json
}

resource "aws_appsync_datasource" "dynamo_db_datasource" {
    api_id = aws_appsync_graphql_api.appsync.id
    name = "dynamo_db_datasource"
    service_role_arn = aws_iam_role.dynamo_db_datasource_role.arn
    type = "AMAZON_DYNAMODB"

    dynamodb_config {
      table_name = aws_dynamodb_table.placeChunks.name
    }
}

# creating Lambda datasource
data "aws_iam_policy_document" "lambda_appsync_policy_document" {
    statement {
        effect = "Allow"
        actions = ["lambda:invokeFunction"]
        resources = [aws_lambda_function.placeUpdateBoard.arn]
    }
}

resource "aws_iam_role" "lambda_datasource_role" {
    name = "lambda_datasource_role"
    assume_role_policy = data.aws_iam_policy_document.appsync_assume_role.json
}

resource "aws_iam_role_policy" "lambda_appsync_policy" {
    name = "lambda_appsync_policy"
    role = aws_iam_role.lambda_datasource_role.id
    policy = data.aws_iam_policy_document.lambda_appsync_policy_document.json
}

resource "aws_appsync_datasource" "lambda_data_source" {
    api_id = aws_appsync_graphql_api.appsync.id
    name = "lambda_data_source"
    service_role_arn = aws_iam_role.lambda_datasource_role.arn
    type = "AWS_LAMBDA"
    lambda_config {
        function_arn = aws_lambda_function.placeUpdateBoard.arn
    }
}

# Attaching dynamodb datasource resolver
resource "aws_appsync_resolver" "dynamobd_resolver" {
    api_id = aws_appsync_graphql_api.appsync.id
    field = "getPlaceChunks"
    type = "Query"
    data_source = aws_appsync_datasource.dynamo_db_datasource.name

    request_template = <<EOF
    {
        "version": "2017-02-28",
        "operation": "GetItem",
        "key": {
            "c": $util.dynamodb.toDynamoDBJson($ctx.args.c),
        },
    }
    EOF

    response_template = <<EOF
    $util.toJson($context.result)
    EOF
}

# Attaching lambda datasource resolver
resource "aws_appsync_resolver" "lambda_resolver" {
    api_id = aws_appsync_graphql_api.appsync.id
    field = "updateBoard"
    type = "Mutation"
    data_source = aws_appsync_datasource.lambda_data_source.name

    request_template = <<EOF
    {
        "version" : "2017-02-28",
        "operation": "Invoke",
        "payload": {
            "arguments": $util.toJson($context.args),
            "identity": $util.toJson($context.identity),
        }
    }
    EOF
}