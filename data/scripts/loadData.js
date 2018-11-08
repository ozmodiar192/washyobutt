var AWS = require("aws-sdk");
var fs = require('fs');

//AWS.config.update({
//    region: "us-east-1",
//    endpoint: "http://localhost:8000"
//});

AWS.config.update({
    region: "us-east-1",
    endpoint: "https://dynamodb.us-east-1.amazonaws.com"
});


var docClient = new AWS.DynamoDB.DocumentClient();

console.log("Importing quotes into DynamoDB. Please wait.");

var allQuotes = JSON.parse(fs.readFileSync('../quoteData.json', 'utf8'));
var quoteCount = Object.keys(allQuotes).length;
console.log("found ",quoteCount," quotes.");
var countParams = {
        TableName: "quoteCount",
        Item: {
           "srcTable": "quotes",
           "qtyQuotes": quoteCount
    }
};

allQuotes.forEach(function(quote) {
    var quoteParams = {
        TableName: "quotes",
        Item: {
            "quoteID": quote.quoteID,
            "quote":  quote.quote,
            "title": quote.title,
            "artist": quote.artist
        }
    };
        

    docClient.put(quoteParams, function(err, data) {
       if (err) {
           console.error("Unable to add quote", quote.quote, ". Error JSON:", JSON.stringify(err, null, 2));
       } else {
           console.log("PutItem succeeded:", quote.quoteID);
       }
    });
});
docClient.put(countParams, function(err, data) {
    if (err) {
        console.error("Unable to add count", quoteCount, ". Error JSON:", JSON.stringify(err, null, 2));
    } else {
        console.log("PutItem succeeded for quoteCount:", quoteCount);
    }
});
