
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const { web } = require('webpack');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false);
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try {
            await config.flightSurety.setTestingMode(true);
        }
        catch (e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true);

    });

    it('(airline) can register an Airline using registerAirline() if it is funded and less than 4 airlines', async () => {

        // ARRANGE
        let newAirline = accounts[3];

        let funded = await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });
        let fee = await config.flightSuretyApp.AIRLINE_FEE.call();

        //Fund the first airline
        if (!funded) {
            await config.flightSuretyApp.fundAirline({ from: config.firstAirline, value: fee });
        }
   
        // ACT
        await config.flightSuretyApp.registerAirline(newAirline, 'new1', { from: config.firstAirline });

        let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline, { from: config.flightSuretyApp.address });

        // ASSERT
        assert.equal(result, true, "Airline should be able to register another airline if it hasn't provided funding");

    });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        // ARRANGE
        let newAirline = accounts[4];
        let registeredNotFundedAirline = accounts[3];

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(newAirline, 'new', { from: registeredNotFundedAirline });
        }
        catch (e) {

        }

        let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline, { from: config.flightSuretyApp.address });

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });

    it('(airline) can register an Airline using registerAirline() only with 50% or more of the votes', async () => {

        // ARRANGE
        let newAirline1 = accounts[4];
        let newAirline2 = accounts[5];
        let newAirline3 = accounts[6];
        let newAirline4 = accounts[7];
        let newAirline5 = accounts[8];

        let funded = await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });
        let fee = await config.flightSuretyApp.AIRLINE_FEE.call();

        //Fund the first airline
        if (!funded) {
            await config.flightSuretyApp.fundAirline({ from: config.firstAirline, value: fee });
        }
   
        // ACT
        await config.flightSuretyApp.registerAirline(newAirline1, 'new1', { from: config.firstAirline });
        await config.flightSuretyApp.fundAirline({ from: newAirline1, value: fee });
        await config.flightSuretyApp.registerAirline(newAirline2, 'new2', { from: config.firstAirline });
        await config.flightSuretyApp.fundAirline({ from: newAirline2, value: fee });
        await config.flightSuretyApp.registerAirline(newAirline3, 'new3', { from: config.firstAirline });
        await config.flightSuretyApp.fundAirline({ from: newAirline3, value: fee });
        await config.flightSuretyApp.registerAirline(newAirline4, 'new4', { from: config.firstAirline });
        await config.flightSuretyApp.fundAirline({ from: newAirline3, value: fee });

        await config.flightSuretyApp.registerAirline(newAirline5, 'new5', { from: config.firstAirline });

        let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline5, { from: config.flightSuretyApp.address });

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register immediately when more than 4 airlines");

        //Other 2 airlines vote as well
        await config.flightSuretyApp.registerAirline(newAirline5, 'new5', { from: newAirline1 });
        await config.flightSuretyApp.registerAirline(newAirline5, 'new5', { from: newAirline2 });

        let voteResult = await config.flightSuretyData.isAirlineRegistered.call(newAirline5, { from: config.flightSuretyApp.address });

        // ASSERT
        assert.equal(voteResult, true, "Airline should be registered when more than 50% voted for it");

    });



});
