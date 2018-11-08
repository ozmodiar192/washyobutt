// required libs and express stuff
var express = require('express');
var app = express(); 
var router = express.Router(); 
var AWS = require("aws-sdk"); 
var Promise = require("promise");

// Config for dynamo stuffs
AWS.config.update({
  region: "us-east-1",
//  endpoint: "http://localhost:8000" });
  endpoint: "http://dynamodb.us-east-1.amazonaws.com" });

//an instance of dynamodb
var dynamodb = new AWS.DynamoDB(); 


// Gets a random number between min and max
function getRandomInt(min,max)
{
    return Math.floor(Math.random()*(max-min+1)+min);
}

// the db params for querying the quote count from dynamo
var countParams = {
  Key: {
    "srcTable": {
      S: "quotes"
      }
  },
      TableName : "quoteCount",
};

// the db params for querying the quote count from dynamo.  This needs to take a parameter (our random number for the quoteID, so it's a function)
function setQuoteParams(rand){
  quoteParams = {
    Key: {
      "quoteID": {
        N: rand.toString()
       }
    },
    TableName : "quotes",
  };
}


// Gets the item count from the table
function getNumQuotes(countParams, cb) {
  dynamodb.getItem(countParams, function(err, data) { if (err) {
    cons
    return cb(new Error("ERROR IN getNumQuotes"),null);
      } else {
          qtyQuotes = data.Item.qtyQuotes.N
          console.log("Got ", qtyQuotes, " quotes")
          cb(null,qtyQuotes);
      }; 
   });
}

//Gets a record from the database
function getQuote(quoteParams, cb) {
  dynamodb.getItem(quoteParams, function(err, data) { if (err) {
    console.error("Unable to query. Error:", JSON.stringify(err, null, 2));
    return cb(new Error("ERROR IN getQuote"),null);
      } else {
          quote = data.Item
          cb(null,quote);
      }; 
   });
}

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

//GET a random quote item from the db and return the json.
router.get('/getQuote', function(req, res, next) {
  // Check if the randMax has been defined.  If not, get it.
  if (typeof randMax == 'undefined') {
    //create a promise for the randMax
    const myRandMax = new Promise(function(resolve, reject) {
      // call getNumQuotes.  If it succeeds, fulfill the promise.  If not, error.
      getNumQuotes(countParams, function (err,data) {
        if (err) {
          console.error("ERROR getting quotes! ", JSON.stringify(err, null, 2));
          reject(err).then(resolved,rejected);
        } else {
          resolve(data);
        };
      });
    });
    // set the randMax
    myRandMax.then(function(data) {
      console.log("Set max random number to ", data)
      randMax = (data)
    })
    // now get a random number using randmax as the max
    .then(function(){
      var myRand = getRandomInt(1,randMax)
      // now pass that random number into the quote params
      setQuoteParams(myRand)
    })
    .then(function(){
      // create a promise for the quote
      const quote = new Promise(function(resolve, reject) {
        getQuote(quoteParams, function (err,data) {
          if (err) {
            console.error("ERROR getting quotes! ", JSON.stringify(err, null, 2));
            reject(err).then(resolved,rejected);
          } else {
            resolve(data);
          };
        });
      });
      quote.then(function(data){
        var myQuote = data
        // set Access-Control header for CORS
        res.header('Access-Control-Allow-Origin', '*')
        // send the response
        res.send(myQuote)
      });
    });
  // this is kind of the same as above, only the randMax is already set so we can just dive in.
  } else {
      //get the random number and pass it into the db params
      var myRand = getRandomInt(1,randMax)
      setQuoteParams(myRand)
      console.log("Using random number ", myRand)
      const quote = new Promise(function(resolve, reject) {
        getQuote(quoteParams, function (err,data) {
          if (err) {
            console.error("ERROR getting quotes! ", JSON.stringify(err, null, 2));
            reject(err).then(resolved,rejected);
          } else {
            resolve(data);
          };
        });
      });
      quote.then(function(data){
        myQuote = data
        console.log("Got quote ", myQuote)
        res.header('Access-Control-Allow-Origin', '*')
        res.send(myQuote)
      });
    };
});

// this gets the quantity of quotes from the db, incase the db gets updated while the app is running.
router.get('/updateCount', function(req, res, next) {
  // create a promise for the randomMax
  const myRandMax = new Promise(function(resolve, reject) {
    getNumQuotes(countParams, function (err,data) {
      if (err) {
        console.error("ERROR getting quotes! ", JSON.stringify(err, null, 2));
        reject(err).then(resolved,rejected);
      } else {
        resolve(data);
      };
    });
  });
  myRandMax.then(function(data) {
    randMax = (data)
    console.log("Set max random number to ", randMax)
    res.header('Access-Control-Allow-Origin', '*')
    res.send(randMax)
  })
});

module.exports = router;
