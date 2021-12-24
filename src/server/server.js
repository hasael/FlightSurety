import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

web3.eth.getAccounts().then(accounts => web3.eth.defaultAccount = accounts[0])

flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log(event)
  web3.eth.getAccounts().then(accounts => {
    flightSuretyApp.methods
      .submitOracleResponse(event.returnValues.index, event.returnValues.airline, event.returnValues.flight, event.returnValues.timestamp, 20)
      .send({ from: accounts[0] }, (err, result) => {
        console.log('index: ' + event.returnValues.index);
        if (err)
          console.error(err);
        else console.log(result);
      });
  });
});

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;


