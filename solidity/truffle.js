module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gasPrice: 11000000000
    },
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gasPrice: 1,
      gas: 234881023
    },
    rinkeby: {
      host: "localhost",
      port: 8545,
      from: "252536b7983e61e287d51459fef9ee034c82c7fb",
      network_id: 4
    }
  }
}
