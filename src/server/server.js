import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let oracles = new Map();


const STATUS_CODE_UNKNOWN = 0;
const STATUS_CODE_ON_TIME = 10;
const STATUS_CODE_LATE_AIRLINE = 20;
const STATUS_CODE_LATE_WEATHER = 30;
const STATUS_CODE_LATE_TECHNICAL = 40;
const STATUS_CODE_LATE_OTHER = 50;
const statusCodes = [STATUS_CODE_UNKNOWN, STATUS_CODE_ON_TIME, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_WEATHER, STATUS_CODE_LATE_TECHNICAL, STATUS_CODE_LATE_OTHER];
const ORACLE_FEE = web3.utils.toWei("1", "ether");
web3.eth.getAccounts().then(accounts => {
  for (let i = 0; i < 20; i++) {
    registerOracle(accounts[6 + i]);
  }
});

function registerOracle(account) {
  flightSuretyApp.methods.isOracleRegistered().call({ from: account, gas: 400000  }, (error, result) => {
    if (error) console.error(error);
    if (result) {
      console.log('Pre registered oracle : ' + account);
      flightSuretyApp.methods.getOracleIndexes().call({ from: account, gas: 400000 })
        .then(indexes => {
          oracles.set(account, indexes);
          console.log(oracles);
        })
      oracles.set(account, result);
      console.log(oracles);
    } else {
      flightSuretyApp.methods.registerOracle().send({ from: account, value: ORACLE_FEE, gas: 400000 })
        .then(result => {
          console.log('Register Oracle:  ' + result);
          flightSuretyApp.methods.getOracleIndexes().call({ from: account, gas: 400000  })
            .then(indexes => {
              oracles.set(account, indexes);
              console.log(oracles);
            })
        })
    }
  })
}

flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('Received event: ' + event);

  oracles.forEach((value, key, map) => {
    console.log(value);
    console.log(value.indexOf(event.returnValues.index) >= 0);
    if (value.indexOf(event.returnValues.index) >= 0) {
      console.log('entered for ' + value);
      let randomIndex = Math.floor((Math.random() * 5) + 0);
      let randomStatus = statusCodes[randomIndex];
      console.log('Returning Status code ' + randomStatus);
      flightSuretyApp.methods
        .submitOracleResponse(event.returnValues.index, event.returnValues.airline, event.returnValues.flight, event.returnValues.timestamp,randomStatus)
        .send({ from: key }, (err, result) => {
          console.log('index: ' + event.returnValues.index);
          if (err)
            console.error(err);
          else console.log(result);
        });
    }
  });


});

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;


