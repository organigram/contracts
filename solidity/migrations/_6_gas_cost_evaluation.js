/// Importing required contracts
// Organs
var deployOrgan = artifacts.require("deployOrgan")
var Organ = artifacts.require("Organ")
// Authentication cost test
var authCostTest = artifacts.require("tests/authCostTest")



module.exports = function(deployer, network, accounts) {

  console.log("---------------------------------------------------------------------------------------------------------------")
  console.log("Testing Authentication through organs")
  console.log("---------------------------------------------------------------------------------------------------------------")
  console.log("-------------------------------------")
  console.log("Available accounts : ")
  accounts.forEach((account, i) => console.log("-", account))
  console.log("-------------------------------------")
  console.log("-------------------------------------")
  console.log("Deploying Organ")
  // 1 organs to deploy: Members list
  deployer.deploy(deployOrgan, "Member Organ", {from: accounts[0]}).then(() => {
  const memberRegistryOrgan = Organ.at(deployOrgan.address)
    console.log("-------------------------------------")
    console.log("Deploying Test contract")

    // Deploy members list management
    deployer.deploy(authCostTest, memberRegistryOrgan.address, {from: accounts[0]}).then(() => {
    const authCostTestDeployed = authCostTest.at(authCostTest.address)
      console.log("-------------------------------------")
      console.log("Adding admin")
      memberRegistryOrgan.addAdmin(accounts[0], true, true, false, false, "Account 0", {from: accounts[0]}).then(() => {

        console.log("-------------------------------------")
        console.log("Adding norm")
        memberRegistryOrgan.addNorm(accounts[0], "Member 0", 1, 1, 1, {from: accounts[0]}).then(() => {
              
          console.log("-------------------------------------")
          console.log("Set up is finished! Account[0] is now a norm of member registry.")
          console.log("-------------------------------------")
            console.log("Calling noAuth()")
            authCostTestDeployed.noAuth({from: accounts[0]}).then(() => {
              console.log("Calling authWithOwner()")
              authCostTestDeployed.authWithOwner({from: accounts[0]}).then(() => {
                console.log("Calling authWithOrgan()")
                authCostTestDeployed.authWithOrgan({from: accounts[0]}).then(() => {

              })
            })
          })
        })
      })
    })
  })

  // Use deployer to state migration tasks.
};
