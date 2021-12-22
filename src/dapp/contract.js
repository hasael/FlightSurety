import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {


    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];

            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, result) => {
                callback(error, payload);
            });
    }
    registerFlight(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .registerFlight(payload.airline, payload.flight, payload.timestamp)
            .estimateGas({ from: self.owner }, (error, estimatedGas) => {
                if (error)
                    console.error('error estimating gas ' + error);
                self.flightSuretyApp.methods
                    .registerFlight(payload.airline, payload.flight, payload.timestamp)
                    .send({ from: self.owner, gas: estimatedGas }, (error, result) => {
                        callback(error, payload);
                    })
            });

    }

    buyInsurance(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight)
            .estimateGas({ from: self.owner, value: this.web3.utils.toWei("0.11", "ether") }, (error, estimatedGas) => {
                if (error)
                    console.error('error estimating gas ' + error);
                self.flightSuretyApp.methods
                    .buyInsurance(payload.airline, payload.flight)
                    .send({ from: self.owner, gas: estimatedGas, value: this.web3.utils.toWei("0.11", "ether") }, (error, result) => {
                        callback(error, payload);
                    })
            });

    }
    initWeb3() {
        /// Find or Inject Web3 Provider
        /// Modern dapp browsers...
        if (window.ethereum) {
            this.web3 = new Web3(window.ethereum);
            try {
                // Request account access
                window.ethereum.enable();
            } catch (error) {
                // User denied account access...
                console.error("User denied account access")
            }
        }
        // Legacy dapp browsers...
        else if (window.web3) {
            this.web3 = new Web3(window.web3.currentProvider);
        }
        // If no injected web3 instance is detected, fall back to Ganache
        else {
            this.web3 = new Web3.providers.HttpProvider('http://localhost:8545');
        }

        this.web3.eth.getAccounts((error, accts) => {

            this.owner = web3.currentProvider.selectedAddress;

            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            console.log('new owner: ' + this.owner);
        });
    }
}