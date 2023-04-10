resource "aws_dynamodb_table" "placeChunks" {
    name = "placeChunks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "c"

    attribute {
      name = "c"
      type = "S"
    }
}

resource "aws_dynamodb_table" "userUpdates" {
    name = "userUpdates"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "uid"

    attribute {
      name = "uid"
      type = "S"
    }
}