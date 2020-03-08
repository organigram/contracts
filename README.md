# Kelsen

Kelsen is a Solidity framework for building governance systems on Ethereum.

Kelsen dictates the governance through the architecture of its organisation.

For example, in order to add a document into a Publications organ, a member of the Redactors organ can call the Publish procedure.  Master procedures make it easy to administer the governance by modifying the architecture and replacing procedures.

- [Organs](docs/01_standardOrgan.md)  
  Organs store the governance data like users, roles, documents...
* [Procedures](docs/02_00_standardProcedure.md)  
  Procedures set rules for modifying this data and the system itself (eg. publication, nomination, election, or any process writable in a smart contract).

## Usage

- Install package from NPM registry with
  ```bash
  npm install --save @organigram/kelsen
  # or
  yarn add @organigram/kelsen
  ```
- Import contracts in your solidity contracts like so
  ```javascript
  import "@organigram/kelsen/contracts/Organ.sol";
  ```
- Import contracts artifacts in your JS code with
  ```javascript
  var contract = require("truffle-contract");
  var data = require("@organigram/kelsen/build/contracts/Organ.json");
  var Organ = contract(data);
  ```

## Third-party services

- [Organigr.am](https://organigr.am) provides Governance-as-a-Service. It uses Kelsen to deploy your whole organisation chart and connects it with external services.

## Contributing

You can contribute to the Kelsen Solidity smart-contracts framework at the original github page.
https://github.com/97network/Kelsen