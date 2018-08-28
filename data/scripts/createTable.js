var AWS = require("aws-sdk");

AWS.config.update({
  region: "us-east-1",
  endpoint: "http://localhost:8000"
});

var dynamodb = new AWS.DynamoDB();

var quoteParams = {
    TableName : "quotes",
    KeySchema: [       
        { AttributeName: "quoteID", KeyType: "HASH"},  //Partition key
    ],
    AttributeDefinitions: [       
        { AttributeName: "quoteID", AttributeType: "N" }
    ],
    ProvisionedThroughput: {       
        ReadCapacityUnits: 10, 
        WriteCapacityUnits: 10
    }
};

var countParams = {
    TableName : "quoteCount",
    KeySchema: [
        { AttributeName: "srcTable", KeyType: "HASH"},
    ],
    AttributeDefinitions: [       
        { AttributeName: "srcTable", AttributeType: "S" }
    ],
    ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5,
    }
};

dynamodb.createTable(quoteParams, function(err, data) {
    if (err) {
        console.error("Unable to create quote table. Error JSON:", JSON.stringify(err, null, 2));
    } else {
        console.log("Created quote table. Table description JSON:", JSON.stringify(data, null, 2));
    }
});
dynamodb.createTable(countParams, function(err, data) {
    if (err) {
        console.error("Unable to create count table. Error JSON:", JSON.stringify(err, null, 2));
    } else {
        console.log("Created count table. Table description JSON:", JSON.stringify(data, null, 2));
    }
});
