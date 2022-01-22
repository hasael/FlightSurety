const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function (deployer) {

    let firstAirline = '0xaa2f9FC58c72a67FCB56d96cD15d444D885d1d45';
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