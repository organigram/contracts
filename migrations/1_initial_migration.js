var Migrations = artifacts.require("Migrations")
var OrganLibrary = artifacts.require("OrganLibrary")
var ProcedureLibrary = artifacts.require("ProcedureLibrary")
var VotePropositionLibrary = artifacts.require("VotePropositionLibrary")

module.exports = async (deployer) => {
  // Deploy the Migrations contract as our only task
  await deployer.deploy(Migrations)
  await deployer.deploy(OrganLibrary)
  await deployer.deploy(ProcedureLibrary)
  await deployer.deploy(VotePropositionLibrary)
}
