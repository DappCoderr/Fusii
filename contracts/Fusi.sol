// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "./FusiBaseStatData.sol";

contract FusiFactory is ERC721, VRFConsumerBase, Ownable, FusiBaseStatData {
    
    event requestedFusi(bytes32 indexed requestedId);
    event FusiCreated(uint256 indexed tokenId);
    
    
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    
    mapping(uint256 => FusiBaseStats) public tokenIdToBattleStats;
    mapping(uint256 => FusiBaseStats) public tokenIdToEvs;
    mapping(uint256 => FusiBaseStats) public tokenIdToIvs;
    
    
    string[] public natures;
    mapping(string => string) public fusiNameToImageURI;
    mapping(uint256 => uint256) public tokenIdToRNGNumber;
    
    bytes32 internal keyHash;
    uint256 internal link_fee;
    uint256 public tokenCounter;

    struct Fusi {
        string nickname;
        string item;
        string ability;
        string nature;
        uint256 level;
    }
    
    Fusi[] public fusis;
    
    
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, uint256 _link_fee) public 
     VRFConsumerBase(_VRFCoordinator, _LinkToken) ERC721("Fusi", "FUSII")
    {
        tokenCounter = 0;
        keyHash = _keyhash;
        link_fee = _link_fee;
        natures = ["Hardy", "Lonely", "Brave", "Adamant", "Naughty", "Bold", "Docile", "Relaxed", "Impish", "Lax", "Timid", "Hasty", "Serious", "Jolly", "Naive", "Modest", "Mild", "Quiet", "Bashful", "Rash", "Calm", "Gentle", "Sassy", "Careful", "Quirky"];
    }
    
    
    function createRandomFusi(uint useProviderSeed) public returns(bytes32) {
        bytes32 requestedId = requestRandomness(keyHash, link_fee, useProviderSeed);
        requestedIdToSender[requestedId] = msg.sender;
        emit requestedFusi(requestedId);
    }
    
    function setIvs(uint256[] memory RNGNumber, string memory fusiName, uint256 tokenId) internal {
        (string memory type1, string memory type2) = getTypeFromName(fusiName);
        FusiBaseStats memory baseStats = fusiNameTofusiBaseStats[fusiName];
        uint256 hpIv = (RNGNumbers[1] % 31) + 1;
        uint256 atkIv = (RNGNumbers[2] % 31) + 1;
        uint256 defIv = (RNGNumbers[3] % 31) + 1;
        uint256 spaIv = (RNGNumbers[4] % 31) + 1;
        uint256 spdIv = (RNGNumbers[5] % 31) + 1;
        uint256 speIv = (RNGNumbers[6] % 31) + 1;
        FusiBaseStats memory ivs = FusiBaseStats({hp: hpIv, def: defIv, atk: atkIv, spa: spaIv, spd: spdIv, type1: type1, type2: type2, number: baseStats.number, fusiName: fusiName});
        FusiBaseStats memory evs = FusiBaseStats({hp: 0, def: 0, atk: 0, spa: 0, spd: 0, spe: 0, type1: type1, type2: type2, number: baseStats.number, fusiName: fusiName});
        tokenIdToIvs[tokenId] = ivs;
        tokenIdToEvs[tokenId] = evs;
    }
    
    
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address owner = requestedIdToSender[requestId];
        uint256 tokenId = tokenCounter;
        requestedIdToTokenId[requestId] = tokenId;
        _safeMint(owner, tokenId);
        tokenIdToRNGNumber[tokenId] = randomNumber;
        takenCounter = tokenCounter + 1;
    }
    
    
    function updateCreatedFusi(uint256 tokenId, string memory fusiName) public onlyOwner {
        uint256[] memory RNGNumbers = getManyRandomNumbers(tokenIdToRNGNumber[tokenId], 11);
        (string memory type1, string memory type2) = getTypeFromName(fusiName);
        string memory nature = natures[(RNGNumbers[8]%natures.length)];
        bool shiny = false;
        uint256 shinyRNG = (RNGNumbers[9] % 4096);
        if(shinyRNG == 0){
            shiny = true;
        } else {
            shiny = false;
        }
        uint256 level = (RNGNumbers[10] % 100) + 1;
        fusis.push(Fusi({
            nickname: fusiName,
            item: "None",
            shiny: shiny,
            ability: "None",
            nature: nature,
            level: level
        }));
        setIvs(RNGNumbers, fusiName, tokenId);
        setBattleStats(fusiName, tokenId);
        emit FusiCreated(tokenCounter);
    }
    
    
    function getTypeFromName(string memory fusiName) public view returns (string memory, string memory) {
        FusiBaseStats memory baseStats = fusiNameTofusiBaseStats[fusiName];
        return (baseStats.type1, baseStats.type2);
    }
    
    
    function setBattleStats(string memory fusiName,  uint256 tokenId) public onlyOwner {
        FusiBaseStats storage battleStats = tokenIdToBattleStats[tokenId];
        FusiBaseStats storage baseStats = fusiNameToFusiBaseStats[fusiName];
        FusiBaseStats storage ivs = tokenIdToIvs[tokenId];
        FusiBaseStats storage evs = tokenIdToEvs[tokenId];
        Fusi storage fusi = fusis[tokenId];

        battleStats.hp = getCalculatedHPStat( baseStats.hp, ivs.hp, evs.hp, fusi.level);
        battleStats.atk = getCalculatedStat( baseStats.atk, ivs.atk, evs.atk, fusi.level); 
        battleStats.def = getCalculatedStat( baseStats.def, ivs.def, evs.def, fusi.level); 
        battleStats.spa = getCalculatedStat( baseStats.spa, ivs.spa, evs.spa, fusi.level); 
        battleStats.spd = getCalculatedStat( baseStats.spd, ivs.spd, evs.spd, fusi.level); 
        battleStats.spe = getCalculatedStat( baseStats.spe, ivs.spe, evs.spe, fusi.level); 
        
        battleStats.type1 = ivs.type1;
        battleStats.type2 = ivs.type2;
        battleStats.fusiName = ivs.fusiName;
        battleStats.number = ivs.number;
    }
    
    
    function getCalculatedStat(uint256 baseStat, uint256 baseStatIv, uint256 baseStatEvs, uint256 level) public view returns (uint256) {
        return ((((2 * baseStat) + baseStatIv + (baseStatEvs / 4)) * level )/ 100) + 5;
    }
    
    
    function getCalculatedHPStat(uint256 baseStat, uint256 baseStatIv, uint256 baseStatEvs, uint256 level) public view returns (uint256) {
        return ((((2 * baseStat) + baseStatIv + (baseStatEvs / 4)) * level )/ 100) + 10 + level;
    }
    
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }
    
    
    function getManyRandomNumbers(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }