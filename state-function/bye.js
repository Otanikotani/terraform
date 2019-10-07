'use strict'

exports.handler = function(event, context, callback) {
    // Create a support case using the input as the case ID, then return a confirmation message
    var myCaseID = event.inputCaseID;
    var myMessage = event.Message + " byed! !";
    var result = {Case: myCaseID, Message: myMessage};
    callback(null, result);
};