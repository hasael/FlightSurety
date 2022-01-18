const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function (deployer) {

    let firstAirline = '0xC0d1dE95F54BB852ef3dCCAD0A5af486bA0879B1';
    let firstAirlineName = 'Acme airline';
    deployer.deploy(FlightSuretyData, firstAirline, firstAirlineName)
        .then(dataContract => {
            console.log('Data contract address' + dataContract.address);
            return deployer.deploy(FlightSuretyApp, dataContract.address)
                .then(() => {
                    let config = {
                        localhost: {
                            url: 'http://localhost:8545',
                            dataAddress: FlightSuretyData.address,
                            appAddress: FlightSuretyApp.address
                        }
                    }
                    dataContract.authorizeCaller(FlightSuretyApp.address);
                    fs.writeFileSync(__dirname + '/../src/dapp/config.json', JSON.stringify(config, null, '\t'), 'utf-8');
                    fs.writeFileSync(__dirname + '/../src/server/config.json', JSON.stringify(config, null, '\t'), 'utf-8');
                });
        });
}