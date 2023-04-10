import { DynamoDBClient, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
const ddbClient = new DynamoDBClient({ region: 'us-east-2' });

export const handler = async(event, context, callback) => {
    let args = event.arguments
    // ensuring arguments are valid
    if (args.x > 1000 || args.x < 0) return {}
    if (args.y > 1000 || args.y < 0) return {}
    if (args.color > 9 || args.color < 0) return {}
    
    // computing indexes to be updated
    let index = args.x + 1000 * args.y
    let chunk = Math.floor(index / 40000)
    let chunk_index = index - (chunk * 40000)
    let colorHex = args.color.toString(16)
    let params = {
        TableName: "placeChunks",
        Key: { c : { S : chunk.toString()} },
        UpdateExpression: `SET v[${chunk_index.toString()}] = :color`,
        ExpressionAttributeValues: { ":color" : { S : args.color.toString(16)} }
    }
    
    // retreiving user data
    let userId = event.identity.username
    console.log("USER_ID_IS: ", userId)
    
    // ensuring 10 seconds have passed since last update user has made
    const secondsSinceEpoch = Math.round(Date.now() / 1000)
    const condition = secondsSinceEpoch - 10
    let userUpdateParams = {
        TableName: "userUpdates",
        Key: { uid: { S : userId }},
        UpdateExpression: `SET et = :epoch`,
        ConditionExpression: `et < :comparison OR attribute_not_exists(et)`,
        ExpressionAttributeValues: { 
            ":epoch" : { N : secondsSinceEpoch.toString() },
            ":comparison" : { N : condition.toString() }
        },
    }
    
    // updating table
    try {
        await ddbClient.send(new UpdateItemCommand(userUpdateParams))
        await ddbClient.send(new UpdateItemCommand(params))
        return {color: args.color.toString(16), x: args.x.toString(), y: args.y.toString()}
    } catch (error) {
        return {error: "unable to update value"}
    }
};