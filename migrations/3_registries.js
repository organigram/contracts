const IPFS = require('ipfs')
const bs58 = require('bs58')

// Kelsen Factory.
// Update this with the current Kelsen Factory.
// A Kelsen Factory can be deployed using the migration 2_kelsen_factory.
const KELSEN_FACTORY_ADDRESS = "0xb584147Ec9Cf03701316f93d3Cd4e01Da7111968"
var kelsenFactory = artifacts.require("KelsenFactory")

// Organ Contract.
var Organ = artifacts.require("Organ")
var nominationsProcedures = {
  "simpleAdminAndMasterNomination": {
    contract: artifacts.require("SimpleAdminAndMasterNominationProcedure"),
    factoryContract: artifacts.require("SimpleAdminAndMasterNominationProcedureFactory")
  },
  "simpleNormNomination": {
    contract: artifacts.require("SimpleNormNominationProcedure"),
    factoryContract: artifacts.require("simpleNormNominationProcedureFactory")
  }
}
var kfc, ipfsNode

async function _deployOrgan(name) {
  const results = await ipfsNode.add(IPFS.Buffer.from(JSON.stringify({ name })))
  if (!results || !results[0])
    throw new Error("Failed to upload organ metadata to IPFS.")
  const { hash } = results[0]
  const bytes = bs58.decode(hash)
  const hash16 = Array.from(bytes, byte => ('0' + (byte & 0xFF).toString(16)).slice(-2)).join('')
  const ipfsHash = "0x" + hash16.substring(4).toLowerCase()
  const hashFunction = parseInt(hash16.substring(0, 2), 16)
  const hashSize = parseInt(hash16.substring(2, 4), 16)

  return kfc.createOrgan(ipfsHash, hashFunction, hashSize)
  .then(result => {
    const log = result && result.logs && result.logs.find(l => l.event === "organCreated")
    return log && log.args && log.args["_address"] && Organ.at(log.args["_address"])
  })
  .then(organ => {
    if (!organ) throw new Error('Organ not found.')
    organ.metadata = hash
    console.log("\nOrgan deployed at")
    console.log(organ.address)
    console.log("Organ metadata on IPFS:")
    console.log(organ.metadata)
    return organ
  })
  .catch(console.error)
}

async function _deployNominationProcedure(procedureType, nominatersOrgan, name) {
  const results = await ipfsNode.add(IPFS.Buffer.from(JSON.stringify({
    name
  })))
  if (!results || !results[0])
    throw new Error("Failed to upload procedure metadata to IPFS.")
  const { hash } = results[0]
  const bytes = bs58.decode(hash)
  const hash16 = Array.from(bytes, byte => ('0' + (byte & 0xFF).toString(16)).slice(-2)).join('')
  const ipfsHash = "0x" + hash16.substring(4).toLowerCase()
  const hashFunction = parseInt(hash16.substring(0, 2), 16)
  const hashSize = parseInt(hash16.substring(2, 4), 16)

  return nominationsProcedures[procedureType].factory.createProcedure(ipfsHash, hashFunction, hashSize, nominatersOrgan)
  .then(result => {
    const log = result && result.logs && result.logs.find(l => l.event === "procedureRegistered")
    return log && log.args && log.args["_address"] &&
      nominationsProcedures[procedureType].contract.at(log.args["_address"])
  })
  .then(procedure => {
    if (!procedure) throw new Error('Procedure not found.')
    procedure.metadata = hash
    console.log("\nProcedure deployed at")
    console.log(procedure.address)
    console.log("Procedure metadata on IPFS:")
    console.log(procedure.metadata)
    return procedure
  })
  .catch(console.error)
}

module.exports = async (_deployer, _network, accounts) => {
  ipfsNode = await IPFS.create()
  if (!ipfsNode)
    throw new Error('IPFS Node not initialized.')

  kfc = await kelsenFactory.at(KELSEN_FACTORY_ADDRESS)
  if (!kfc.address)
    throw new Error('No Kelsen Factory deployed.')
  console.log("Using Kelsen Factory at", kfc.address)

  // Load procedures factories.
  const proceduresFactoriesLoaded = await Promise.all(
    [
      "simpleNormNomination",
      "simpleAdminAndMasterNomination"
    ].map(key =>
      kfc.getFactoryData(key)
      .then(factoryData => nominationsProcedures[key].factoryContract.at(factoryData.contractAddress))
      .then(factory => ({ key, factory }))
    )
  )
  proceduresFactoriesLoaded.forEach(({ key, factory }) => {
    nominationsProcedures[key].factory = factory
  })

  console.log("\n### Deploying organs")
  const [
    directionGenerale,
    registreDuPersonnel,
    registreJuridique,
    registresComptables
  ] = await Promise.all([
    _deployOrgan("Direction générale"),
    _deployOrgan("Registre du personnel"),
    _deployOrgan("Documents juridiques"),
    _deployOrgan("Registres comptables")
  ])
  
  // console.log("\n### Deploying procedures")
  const [
    nominateDirector,
    updateRegistry,
    administerSystem
  ] = await Promise.all([
    _deployNominationProcedure("simpleNormNomination", directionGenerale.address, "Nomination du directeur général"),
    _deployNominationProcedure("simpleNormNomination", directionGenerale.address, "Édition des registres obligatoires"),
    _deployNominationProcedure("simpleAdminAndMasterNomination", directionGenerale.address, "Modification du système")
  ])
          
  console.log("\n### Setting organ parameters.")
  await Promise.all([
    // Adding Masters
    directionGenerale.addMaster(administerSystem.address, true, true)
    .then(_ => console.log("Added Master", directionGenerale.address, administerSystem.address)),
    registreDuPersonnel.addMaster(administerSystem.address, true, true)
    .then(_ => console.log("Added Master", registreDuPersonnel.address, administerSystem.address)),
    registreJuridique.addMaster(administerSystem.address, true, true)
    .then(_ => console.log("Added Master", registreJuridique.address, administerSystem.address)),
    registresComptables.addMaster(administerSystem.address, true, true)
    .then(_ => console.log("Added Master", registresComptables.address, administerSystem.address)),
    // Adding Admins
    directionGenerale.addAdmin(nominateDirector.address, true, true, false, false)
    .then(_ => console.log("Added Admin", directionGenerale.address, nominateDirector.address)),
    registreJuridique.addAdmin(updateRegistry.address, true, true, false, false)
    .then(_ => console.log("Added Admin", registreJuridique.address, updateRegistry.address)),
    registreDuPersonnel.addAdmin(updateRegistry.address, true, true, false, false)
    .then(_ => console.log("Added Admin", registreDuPersonnel.address, updateRegistry.address)),
    registresComptables.addAdmin(updateRegistry.address, true, true, false, false)
    .then(_ => console.log("Added Admin", registresComptables.address, updateRegistry.address)),
    // Adding Temp Admins
    directionGenerale.addAdmin(accounts[0], true, true, false, false)
    .then(_ => console.log("Added Temp Administrator", directionGenerale.address, accounts[0]))
  ])
          
  console.log("\n### Adding entries");
  await directionGenerale.addNorm(accounts[0], "0x", 0, 0)
  .then(_ => console.log("Added entry", directionGenerale.address, accounts[0]))
          
  console.log("\n### Cleaning installation")
  // Removing Temp Admins
  await directionGenerale.removeAdmin(accounts[0])
  .then(_ => console.log("Removed temp admin", directionGenerale.address, accounts[0]))
  await Promise.all([
    // Removing Temp Masters
    directionGenerale.removeMaster(accounts[0])
    .then(_ => console.log("Removed master", directionGenerale.address, accounts[0])),
    registreDuPersonnel.removeMaster(accounts[0])
    .then(_ => console.log("Removed master", registreDuPersonnel.address, accounts[0])),
    registreJuridique.removeMaster(accounts[0])
    .then(_ => console.log("Removed master", registreJuridique.address, accounts[0])),
    registresComptables.removeMaster(accounts[0])
    .then(_ => console.log("Removed master", registresComptables.address, accounts[0])),
  ])

  console.log("\n##########################\n### Success!\n\n")
  console.log("[")
  console.log("   \""+directionGenerale.address+"\",    // [Organ] Direction générale")
  console.log("   \""+registreDuPersonnel.address+"\",    // [Organ] Registre du personnel")
  console.log("   \""+registreJuridique.address+"\",    // [Organ] Documents juridiques")
  console.log("   \""+registresComptables.address+"\",    // [Organ] Registres comptables")
  console.log("   \""+administerSystem.address+"\",    // [Procedure] p0 Modification du système")
  console.log("   \""+nominateDirector.address+"\",    // [Procedure] p1 Nomination du directeur général")
  console.log("   \""+updateRegistry.address+"\",    // [Procedure] p2 Édition des registres obligatoires")
  console.log("]")
}