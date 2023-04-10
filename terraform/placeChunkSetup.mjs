import { DynamoDBClient, BatchWriteItemCommand } from "@aws-sdk/client-dynamodb";
const ddbClient = new DynamoDBClient({ region: 'us-east-2' });

// resets the board (creates 25 chunks containing a list filled with 40000 0's)
export const handler = async(event) => {
    let values = Array(40000).fill({ S : '0'})
    let requests = []
    for (let chunk = 0; chunk < 25; chunk++) {
        requests.push({
            PutRequest: {
                Item: {
                    c: { S : chunk.toString() },
                    v: { L : values }
                }
            }
        })
    }
    let params = {
        RequestItems: {
            placeChunks: requests
        }
    }
    
    try {
        await ddbClient.send(new BatchWriteItemCommand(params));
        return { body: 'success' }
    } catch (err) {
        console.log(err)
        return { error: err }
    }
};