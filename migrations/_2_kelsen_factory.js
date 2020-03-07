// Kelsen Factory.
var KelsenFactory = artifacts.require("KelsenFactory")
// Procedures Factories.
var CyclicalManyToOneElectionProcedureFactory = artifacts.require("CyclicalManyToOneElectionProcedureFactory")
var SimpleAdminAndMasterNominationProcedureFactory = artifacts.require("SimpleAdminAndMasterNominationProcedureFactory")
var SimpleNormNominationProcedureFactory = artifacts.require("SimpleNormNominationProcedureFactory")
// Libraries.
var OrganLibrary = artifacts.require("OrganLibrary")
var ProcedureLibrary = artifacts.require("ProcedureLibrary")
var CyclicalElectionLibrary = artifacts.require("CyclicalElectionLibrary")


module.exports = async (deployer, _network, _accounts) => {
  // Deploy libraries.
  await deployer.deploy(OrganLibrary)
  await deployer.deploy(ProcedureLibrary)
  await deployer.deploy(CyclicalElectionLibrary)

  // Deploy and create a kelsen factory.
  deployer.link(OrganLibrary, KelsenFactory)
  const kelsenFactory = await KelsenFactory.new()

  // Deploy and create procedures factories.
  deployer.link(ProcedureLibrary, [
    CyclicalManyToOneElectionProcedureFactory,
    SimpleAdminAndMasterNominationProcedureFactory,
    SimpleNormNominationProcedureFactory
  ])
  deployer.link(CyclicalElectionLibrary, CyclicalManyToOneElectionProcedureFactory)
  const cyclicalManyToOneElectionProcedureFactory = await CyclicalManyToOneElectionProcedureFactory.new()
  const simpleAdminAndMasterNominationProcedureFactory = await SimpleAdminAndMasterNominationProcedureFactory.new()
  const simpleNormNominationProcedureFactory = await SimpleNormNominationProcedureFactory.new()

  // Register procedures factories in Kelsen.
  await kelsenFactory.registerProcedureFactory("cyclicalManyToOneElection", cyclicalManyToOneElectionProcedureFactory.address, 1)
  await kelsenFactory.registerProcedureFactory("simpleAdminAndMasterNomination", simpleAdminAndMasterNominationProcedureFactory.address, 1)
  await kelsenFactory.registerProcedureFactory("simpleNormNomination", simpleNormNominationProcedureFactory.address, 1)

  console.log("\nProcedures factories:")
  const proceduresCount = await kelsenFactory.proceduresCount()
  const proceduresNames = []
  for(var i = 0; i < proceduresCount; ++i)
    proceduresNames.push(await kelsenFactory.proceduresNames(i))
  console.log(proceduresNames)

  console.log("\nKelsen factory deployed at")
  console.log(kelsenFactory.address)
}