# AWS Place

Fully serverless implemenations of reddits r/place built using AWS managed services.
demo at https://place.eslamira.com/

## Deploying backend services

1. Create an access key in AWS IAM and update terraform/main.tf.
2. Run the following commands

```bash
# initialise terraform
terraform init

# deploy backend services
terraform apply
```

## Setting up front end

Once the backend has been initialized. Create a file called aws-exports.js in the src folder.
Add the following to the file

```bash
const awsmobile = {
    "aws_project_region": "us-east-2",
    "aws_appsync_graphqlEndpoint": "OBTAIN FROM APPSYNC",
    "aws_appsync_region": "us-east-2",
    "aws_appsync_authenticationType": "API_KEY",
    "aws_appsync_apiKey": "OBTAIN FROM APPSYNC",
    "aws_cognito_region": "us-east-2",
    "aws_user_pools_id": "OBTAIN FROM COGNITO",
    "aws_user_pools_web_client_id": "OBTAIN FROM COGNITO",
};

export default awsmobile;
```
Obtain the required endpoint, keys and ids from the respective AWS services in the AWS console or use terraform state show command.

run the follwing commands
```bash
npm install
npm run dev
```
