
var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 20;

  // Watch contract events
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });


  it('can register oracles', async () => {

    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
      await config.flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
      let result = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a] });
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }
  });

  it('can request flight status', async () => {

    // ARRANGE
    let flight = 'ND1309'; // Course number
    let timestamp = Math.floor(Date.now() / 1000);


    let fee = await config.flightSuretyApp.AIRLINE_FEE.call();
    let insuranceFee = await config.flightSuretyApp.MAXIMUM_INSURANCE_FEE.call();
    let funded = await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });

    //Fund the first airline
    if (!funded) {
      await config.flightSuretyApp.fundAirline({ from: config.firstAirline, value: fee });
    }

    await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });

    //Register flight
    await config.flightSuretyApp.registerFlight(config.firstAirline, flight, timestamp, { from: config.firstAirline });


    // Submit a request for oracles to get status information for a flight
    await config.flightSuretyApp.fetchFlightStatus(config.airlineName, flight, timestamp);


    let index = await config.flightSuretyApp.getLastFlightRequestIndex.call(config.firstAirline, flight, { from: accounts[0] });

    console.log("index: " + index);
    await config.flightSuretyApp.buyInsurance(config.airlineName, flight, { from: accounts[30], value: insuranceFee });

    // ACT
    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    let enteredCount = 0;
    for (let a = 1; a < TEST_ORACLES_COUNT; a++) {

      // Get oracle information
      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a] });
      for (let idx = 0; idx < 3; idx++) {
        if (oracleIndexes[idx].toString() == index.toString()) {
          try {
            // Submit a response...it will only be accepted if there is an Index match
            await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx], config.firstAirline, flight, timestamp, STATUS_CODE_LATE_AIRLINE, { from: accounts[a] });
            console.log('Submitted correctly for: ' + oracleIndexes[idx]);
            enteredCount++;
          }
          catch (e) {
            // Enable this when debugging
            console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp, e.message);
          }
        }

      }
    }

    let userBalance = await config.flightSuretyApp.getUserBalance.call({ from: accounts[30] });
    console.log(userBalance.toString());
    console.log('submitted: ' + enteredCount);
    if (enteredCount >= 3) {
      assert.equal(userBalance.toString(), (insuranceFee * 1.5).toString(), "Reimbursed amount must be at 50% of the invested value");
    }

  });
  it('refund user in case of delayed flight', async () => {
    /*
        // ARRANGE
        let flight = 'ND1309'; // Course number
        let timestamp = Math.floor(Date.now() / 1000);
    
    
        let fee = await config.flightSuretyApp.AIRLINE_FEE.call();
        let funded = await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });
    
        //Fund the first airline
        if (!funded) {
          await config.flightSuretyApp.fundAirline({ from: config.firstAirline, value: fee });
        }
    
        await config.flightSuretyData.isAirlineFunded.call(config.firstAirline, { from: config.flightSuretyApp.address });
    
        //Register flight
        await config.flightSuretyApp.registerFlight(config.firstAirline, flight, timestamp, { from: config.firstAirline });
    
        // Submit a request for oracles to get status information for a flight
        await config.flightSuretyApp.fetchFlightStatus(config.airlineName, flight, timestamp);
        // ACT
        // Since the Index assigned to each test account is opaque by design
        // loop through all the accounts and for each account, all its Indexes (indices?)
        // and submit a response. The contract will reject a submission if it was
        // not requested so while sub-optimal, it's a good test of that feature
        for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
    
          // Get oracle information
          let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a] });
          console.log("oracle indexes: " + oracleIndexes);
          for (let idx = 0; idx < 3; idx++) {
    
            try {
              // Submit a response...it will only be accepted if there is an Index match
              await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx], config.firstAirline, flight, timestamp, STATUS_CODE_ON_TIME, { from: accounts[a] });
              console.log('Submitted correctly for: ' + oracleIndexes[idx]);
            }
            catch (e) {
              // Enable this when debugging
              console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp);
            }
    
          }
        }
    
    */
  });


});
