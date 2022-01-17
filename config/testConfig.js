
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function (accounts) {

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0xa73C0a824EAEF0D7DbB1C302c5Ee76C71f971074",
        "0xb78A7E9D649587C7C25237d9aDF557C606625E2a",
        "0xAa025086Bae060F9d8d4B6FA512907b095112eE1",
        "0x09155DCdbFAc768272d8f77055118EB7A5B73EF1",
        "0xbF38211008C1793C8B659daA49d57857A7471915",
        "0xF0e9d28C27118DC5297A378f50d8099A492b963F",
        "0x1718dfD4Ee0A341A164D754cc6A5d1cA7ABeeB54",
        "0x506Bcd9dd49730351138D2517E3e0d2966Dd519e",
        "0x340A62F6D6E50584b148674E8428B132D727BBaC"
    ];


    let owner = accounts[0];
    let airlineName = 'Acme'
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new(firstAirline, airlineName);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);


    return {
        owner: owner,
        firstAirline: firstAirline,
        airlineName: airlineName,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};