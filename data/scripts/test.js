var AWS = require("aws-sdk");

// AWS.config.update({
//   region: "us-west-2",
//   endpoint: "http://localhost:8000"
// });

AWS.config.update({
    region: "us-east-1",
    endpoint: "https://dynamodb.us-east-1.amazonaws.com"
});


var docClient = new AWS.DynamoDB.DocumentClient();
var dynamodb = new AWS.DynamoDB();

console.log("Querying for quote count");

var countParams = {
    TableName : "quoteCount",
    KeyConditionExpression: "srcTable = :quotes",
    ExpressionAttributeValues: {
    ':quotes': 'quotes'
    },
};
var quoteParams = {
    TableName : "quotes",
};


docClient.query(countParams, function(err, data) {
    if (err) {
        console.error("Unable to query. Error:", JSON.stringify(err, null, 2));
    } else {
        console.log("Query succeeded.");
        data.Items.forEach(function(item) {
            numQuotes = item.qtyQuotes
        });
        console.log("Total number of records: ", numQuotes)
    }
});

  
function onScan(err, data) {
    if (err) {
        console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
    } else {
        // print all the movies
        console.log("Scan succeeded.");
        data.Items.forEach(function(quote) {
           console.log(
                "\nQuote ID: ", quote.quoteID, "\n",
                "Arist: ", quote.artist, "\n", 
                "song: ", quote.title, "\n",
                "Quote: ", quote.quote), "\n";
               
        });

        // continue scanning if we have more quote, because
        // scan can retrieve a maximum of 1MB of data
        if (typeof data.LastEvaluatedKey != "undefined") {
            console.log("Scanning for more...");
            params.ExclusiveStartKey = data.LastEvaluatedKey;
            docClient.scan(params, onScan);
        }
    }
}

docClient.scan(quoteParams, onScan)
