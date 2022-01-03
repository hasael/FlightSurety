import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let oracles = new Map();

web3.eth.getAccounts().then(accounts => {
  registerOracle(accounts[6]);
  registerOracle(accounts[5]);
  registerOracle(accounts[7]);
  registerOracle(accounts[8]);
  registerOracle(accounts[9]);
});

function registerOracle(account) {
  flightSuretyApp.methods.getOracleIndexes().call({ from: account }, (error, result) => {
    if (error) console.error(error);
    if (!error) {
      console.log('Pre registered oracle for: ' + result);
      oracles.set(account, result);
      console.log(oracles);
    } else {
      flightSuretyApp.methods.registerOracle().send({ from: account, value: web3.utils.toWei("1", "ether"), gas: 200000 })
        .then(result => {
          console.log('Register Oracle:  ' + result);
          flightSuretyApp.methods.getOracleIndexes().call({ from: account })
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
      flightSuretyApp.methods
        .submitOracleResponse(event.returnValues.index, event.returnValues.airline, event.returnValues.flight, event.returnValues.timestamp, 20)
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


