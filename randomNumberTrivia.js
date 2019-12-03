console.log("Random Facts");

var request = new XMLHttpRequest();
var url = "http://numbersapi.com/random/trivia";

request.open("GET",url,false);
request.send();

var response = request.response;

document.getElementById('random-number-trivia').innerHTML = response;
