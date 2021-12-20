var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "bar devote sauce paddle time famous survey keep birth simple photo orient";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
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