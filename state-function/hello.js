'use strict'

exports.handler = function(event, context, callback) {
    // Create a support case using the input as the case ID, then return a confirmation message
    var inputStatus = event.inputStatus;
    var result = {Status: inputStatus};
    callback(null, result);
};