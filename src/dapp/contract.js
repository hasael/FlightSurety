import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {


    constructor(network, callback) {

        let config = Config[network];
        this.initWeb3();
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.owner = null;
        this.passengers = [];
        callback();
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: web3.currentProvider.selectedAddress }, callback);
    }

    getFlights(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getFlightsList()
            .call({ from: web3.currentProvider.selectedAddress }, callback);
    }

    fetchFlightStatus(flight, airline, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: web3.currentProvider.selectedAddress }, (error, result) => {
                callback(error, payload);
            });
    }

    registerAirline(name, airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerAirline(airlineAddress, name)
            .send({ from: web3.currentProvider.selectedAddress }, (error, result) => {
                callback(error, result);
            });
    }

    registerFlight(flight, callback) {
        let self = this;
        let payload = {
            airline: web3.currentProvider.selectedAddress,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .registerFlight(payload.airline, payload.flight, payload.timestamp)
            .send({ from: web3.currentProvider.selectedAddress }, (error, result) => {
                callback(error, payload);
            });

    }

    buyInsurance(flight, airline, value, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight)
            .send({ from: web3.currentProvider.selectedAddress, value: this.web3.utils.toWei(value, "ether") }, (error, result) => {
                callback(error, payload);
            });

    }

    fundAirline(fundValue, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fundAirline()
            .send({ from: web3.currentProvider.selectedAddress, value: this.web3.utils.toWei(fundValue, "ether") }, (error, result) => {
                callback(error, result);
            });
    }

    withdrawBalance(value, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawUserBalance(this.web3.utils.toWei(value, "ether"))
            .send({ from: web3.currentProvider.selectedAddress }, (error, result) => {
                callback(error, result);
            });
    }

    getBalance(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getUserBalance()
            .call({ from: web3.currentProvider.selectedAddress }, callback);
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
            console.log('new owner: ' + this.owner);
        });
    }
}