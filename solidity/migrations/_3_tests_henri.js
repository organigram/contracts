
/// Importing required contracts
// Organs
var deployOrgan = artifacts.require("deployOrgan")
var Organ = artifacts.require("Organ")
// Deposit Funds procedure
var deployDepositFundsProcedure = artifacts.require("deploy/deployDepositFundsProcedure")
var depositFundsProcedure = artifacts.require("procedures/depositFundsProcedure")
// Vote on masters
var deployVoteOnAdminsAndMastersProcedure = artifacts.require("deploy/deployVoteOnAdminsAndMastersProcedure")
var voteOnAdminsAndMastersProcedure = artifacts.require("procedures/voteOnAdminsAndMastersProcedure")
// Vote on member addition
var deployVoteOnNormsProcedure = artifacts.require("deploy/deployVoteOnNormsProcedure")
var voteOnNormsProcedure = artifacts.require("procedures/voteOnNormsProcedure")
// Vote on expense
var deployVoteOnExpenseProcedure = artifacts.require("deploy/deployVoteOnExpenseProcedure")
var voteOnExpenseProcedure = artifacts.require("procedures/voteOnExpenseProcedure")


module.exports = function(deployer, network, accounts) {

  console.log("---------------------------------------------------------------------------------------------------------------")
  console.log("Full system deploy")
  console.log("---------------------------------------------------------------------------------------------------------------")
  console.log("-------------------------------------")
  console.log("Available accounts : ")
  accounts.forEach((account, i) => console.log("-", account))
  console.log("-------------------------------------")
  console.log("-------------------------------------")
  console.log("Deploying Organs")
  // 6 organs to deploy: Admins, Members, President, Moderators, Secretary, Active contracts
  // Deploy First organ (admins)
  deployer.deploy(deployOrgan, "Admins Organ", {from: accounts[0]}).then(() => {
  const memberRegistryOrgan = Organ.at(deployOrgan.address)
 
    console.log("-------------------------------------")
    console.log("Deploying Procedures")
    // Deploying 5 procedures: Presidential election, moderators election, contract promulgation, simple nomination, constitutionnal reform
    // Deploy presidential election procedure
    voteDurationInSeconds = 60*3
    deployer.deploy(deployVoteOnNormsProcedure, memberRegistryOrgan.address, memberRegistryOrgan.address, 0x0000 , memberRegistryOrgan.address, 40, voteDurationInSeconds, voteDurationInSeconds, {from: accounts[0]}).then(() => {
    const presidentialElection = voteOnNormsProcedure.at(deployVoteOnNormsProcedure.address)


          })
        })
  // Use deployer to state migration tasks.
};
