var AWS = require("aws-sdk");

AWS.config.update({
  region: "us-east-1",
  endpoint: "http://localhost:8000"
});

var dynamodb = new AWS.DynamoDB();

var quoteParams = {
    TableName : "quotes",
};

var countParams = {
    TableName : "quoteCount",
};

dynamodb.deleteTable(quoteParams, function(err, data) {
    if (err) {
        console.error("Unable to delete quote table. Error JSON:", JSON.stringify(err, null, 2));
    } else {
        console.log("Deleted quote table. Table description JSON:", JSON.stringify(data, null, 2));
    }
dynamodb.deleteTable(countParams, function(err, data) {
    if (err) {
        console.error("Unable to delete count table. Error JSON:", JSON.stringify(err, null, 2));
    } else {
        console.log("Deleted count table. Table description JSON:", JSON.stringify(data, null, 2));
    }
});
});
