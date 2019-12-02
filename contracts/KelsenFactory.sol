pragma solidity >=0.4.22 <0.7.0;

/// @title Kelsen factory contract for on-chain deployments.
import "./Organ.sol";

contract KelsenFactory {

    struct FactoryData {
        address contractAddress;
        uint16 version;
    }

    // Store organs created directly.
    address public owner;
    address[] public organs;
    // Store procedures factories.
    string[] public proceduresNames;
    uint public proceduresCount;
    mapping (string => FactoryData) proceduresFactories;

    // Events.
    event organCreated(address _from, address _address);
    event procedureFactoryRegistered(address _from, string _name, address _contractAddress, uint16 _version);

    constructor () public {
        owner = msg.sender;
    }

    function createOrgan(bytes32 _metadataIpfsHash, uint8 _metadataHashFunction, uint8 _metadataHashSize)
        public returns (address)
    {
        // @TODO : Check if enough gas.

        // Create instance, add instance to array, return instance.
        address organAddress = address(new Organ(msg.sender, _metadataIpfsHash, _metadataHashFunction, _metadataHashSize));
        organs.push(organAddress);

        emit organCreated(msg.sender, organAddress);
        return organAddress;
    }

    function getFactoryData(string memory _name)
        public view returns (address contractAddress, uint16 version)
    {
        FactoryData memory factoryData = proceduresFactories[_name];
        return (
            factoryData.contractAddress,
            factoryData.version
        );
    }

    function registerProcedureFactory(string memory _name, address _contractAddress, uint16 _version)
        public
    {
        require(msg.sender == owner, "Not authorized.");
        FactoryData memory factoryData = proceduresFactories[_name];
        if (factoryData.contractAddress != address(0)) {
            require(_version > factoryData.version, "Wrong version number.");
            factoryData.version = _version;
            factoryData.contractAddress = _contractAddress;
        }
        else {
            require(_version >= 1, "Wrong version number.");
            factoryData = FactoryData({
                contractAddress: _contractAddress,
                version: _version
            });
            // Save name of factory.
            proceduresNames.push(_name);
            proceduresCount = proceduresCount + 1;
        }
        proceduresFactories[_name] = factoryData;

        emit procedureFactoryRegistered(msg.sender, _name, _contractAddress, _version);
    }
}