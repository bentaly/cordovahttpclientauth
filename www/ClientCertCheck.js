
var exec = require("cordova/exec");

var ClientCertCheck = function () {
    this.name = "ClientCertCheck";
};

ClientCertCheck.prototype.checkCert = function (successCallback, failureCallback, host) {
    exec(successCallback, failureCallback, "ClientCertCheck", "open", [{host: host}]);
};

module.exports = new ClientCertCheck();
