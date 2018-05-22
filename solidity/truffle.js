module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      host: "localhost",
      port: 8545,
      from: "252536b7983e61e287d51459fef9ee034c82c7fb",
      network_id: 4
    }
  }
}
