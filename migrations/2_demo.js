var ipfsClient = require("ipfs-http-client")
var CID = require("cids")
var OrganLibrary = artifacts.require("OrganLibrary")
var ProcedureLibrary = artifacts.require("ProcedureLibrary")
var VotePropositionLibrary = artifacts.require("VotePropositionLibrary")
var Organ = artifacts.require("Organ")
var SimpleNominationProcedure = artifacts.require("SimpleNominationProcedure")
var VoteProcedure = artifacts.require("VoteProcedure")

const EMPTY_BYTES_32 = "0x00000000000000000000000000000000"

module.exports = async (deployer, network, accounts) => {
  if (network !== "development" && network !== "develop")
    return;

  const from = accounts[0]
  console.log("Current account", from)

  // Connect to IPFS Daemon API Server running locally.
  ipfs = await ipfsClient('http://localhost:5002')
  if (!ipfs)
    throw new Error("Run `yarn ipfs` to start an IPFS node locally.")

  await Organ.link(OrganLibrary)
  await SimpleNominationProcedure.link(ProcedureLibrary)
  await VoteProcedure.link(ProcedureLibrary)
  await VoteProcedure.link(VotePropositionLibrary)

  // Deploying organs and procedures.
  const admins = await Organ.new(from, EMPTY_BYTES_32, 0, 0, { from })
  console.log(`* admins: ${admins.address}`)
  const norms = await Organ.new(from, EMPTY_BYTES_32, 0, 0, { from })
  console.log(`* norms: ${norms.address}`)
  const nominateAdmins = await SimpleNominationProcedure.new(EMPTY_BYTES_32, 0, 0, admins.address)
  console.log(`- nominateAdmins: ${nominateAdmins.address}`)
  const voteNorms = await VoteProcedure.new(
    EMPTY_BYTES_32, 0, 0,   // Metadata.
    admins.address,         // Voters.
    admins.address,         // Vetoers.
    admins.address          // Enactors.
  )
  console.log(`- voteNorms: ${voteNorms.address}`)
  const updateSystem = await SimpleNominationProcedure.new(EMPTY_BYTES_32, 0, 0, admins.address)
  console.log(`- updateSystem: ${updateSystem.address}`)

  // Configuring procedures on organs.
  // 0xC0 = 11000000 = can add and remove procedures.
  // 0x0C = 00001100 = can add and remove entries.
  await admins.replaceProcedure(from, from, "0xffff")
  .then(data => console.log(`admins.replaceProcedure(from, from, "0xffff")`))
  await admins.addEntry(from, EMPTY_BYTES_32, 0, 0)
  .then(data => console.log(`admins.addEntry(from, EMPTY_BYTES_32, 0, 0)`))
  await admins.addProcedure(nominateAdmins.address, "0xffff")
  .then(data => console.log(`admins.addProcedure(nominateAdmins.address, "0xffff")`))
  await admins.replaceProcedure(from, updateSystem.address, "0xffff")
  .then(data => console.log(`admins.replaceProcedure(from, updateSystem.address, "0xffff")`))
  await norms.addProcedure(voteNorms.address, "0xffff")
  .then(data => console.log(`norms.addProcedure(voteNorms.address, "0xffff")`))
  await norms.replaceProcedure(from, updateSystem.address, "0xffff")
  .then(data => console.log(`norms.replaceProcedure(from, updateSystem.address, "0xffff")`))

  // Logs.
  console.log("\n\nDemo deployed.\n\n")
  console.log({
    "admins": {
      "address": admins.address,
      "procedures": await getProcedures(admins),
      "entries": await getEntries(admins),
      "metadata": await admins.getMetadata().then(result => multihashToCid(result).ipfsio),
    },
    "norms": {
      "address": norms.address,
      "procedures": await getProcedures(norms),
      "entries": await getEntries(norms),
      "organData": await norms.getMetadata().then(result => multihashToCid(result).ipfsio),
    },
    "nominateAdmins": {
      "address": nominateAdmins.address,
      "nominatersOrgan": await nominateAdmins.nominatersOrgan()
    },
    "voteNorms": {
      "address": voteNorms.address,
      "votersOrgan": await voteNorms.votersOrgan(),
      "vetoersOrgan": await voteNorms.vetoersOrgan(),
      "enactorsOrgan": await voteNorms.enactorsOrgan()
    },
    "updateSystem": {
      "address": updateSystem.address,
      "nominatersOrgan": await updateSystem.nominatersOrgan()
    }
  })
}

const getProcedures = async organ => {
  const length = (await organ.getProceduresLength()).toString()
  if (length === "0")
    return {}

  var i = 0
  var proceduresPromises = []
  for (i ; String(i) != length ; i++) {
    proceduresPromises.push(
      organ.getProcedure(i)
      .catch(e => console.log("Error", e.message))
      .then(async result => {
        return {
          procedure: result.procedure,
          permissions: result.permissions.toString()
        }
      })
      .catch(e => console.error("Error", e.message))
    )
  }
  const _procedures = await Promise.all(proceduresPromises)
  var procedures = {}
  console.log(`getProcedures(${organ.address}):`)
  _procedures.filter(p => !!p).forEach(({ procedure, permissions }) => {
    procedures[procedure] = permissions
    console.log(`- ${procedure} -> ${permissions}`)
  })
  return procedures
}

const getEntries = async organ => {
  const length = (await organ.getEntriesLength()).toString()
  if (length === "0")
    return []

  var i = 1
  var promises = []
  for (i ; String(i) != length ; i++) {
    promises.push(
      organ.getEntry(i)
      .catch(e => console.error("Error", e.message))
    )
  }
  console.log(`getEntries(${organ.address})`)
  return Promise.all(promises)
  .then(entries => {
    entries.forEach((entry, i) => {
      console.log(`- ${i} -> ${entry.addr}\n${entry.ipfsHash}`)
    })
    return entries
  })
}

function multihashToCid(result) {
  const { ipfsHash, hashFunction, hashSize } = result
  const multihash = `${hashSize.toString('hex')}${hashFunction.toString('hex')}${ipfsHash}`
  // console.log("multihash\n" + multihash)
  const cid = ""// new CID(multihash.toString('hex'))
  return {
    cid, ipfsio: `https://ipfs.io/ipfs/${cid}`
  }
}