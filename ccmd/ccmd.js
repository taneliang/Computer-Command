var applescript = require('applescript');
var express = require('express');
var bodyParser = require("body-parser");
var app = express();

app.use(bodyParser.text());

app.post('/', function(req, res) {
    var body = req.body;
    body.replace("/\\\\/g", "\\");
    console.dir(body);
    var script = 'tell application "Computer Command" to process input "' + body + '"'
    console.dir(script)
    
    applescript.execString(script, function(err, rtn) {
      console.dir(rtn);
      res.send(rtn);
    });
}); 

app.listen(2434);