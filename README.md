# Kelsen

Kelsen is a Solidity framework for building governance systems on Ethereum.

In Kelsen, organs store the governance data like users, roles or documents. Procedures are then used to modify this data in a specific way (eg. publication or nomination, election, or any process writable in a smart contract). Kelsen dictates the governance through the architecture of its organisation. For example, in order to add a document into a Publications organ, a member of the Redactors organ can call the Publish procedure.  Master procedures make it easy to administer the governance by modifying the architecture and replacing procedures.

## Documentation
* [Organs](docs/01_standardOrgan.md)
* [Procedures](docs/02_00_standardProcedure.md)