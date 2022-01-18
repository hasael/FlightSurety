var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "stable excuse tray metal upon fire burger abstract unable quote tomato hidden";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '5778',
      gas: 6721975,
      websockets: true
    }
  },
  compilers: {
    solc: {
      version: "^0.8.10"
    }
  }
};