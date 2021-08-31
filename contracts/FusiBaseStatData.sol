// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FusiBaseStatData is Ownable {

    mapping(string => FusiBaseStats) public fusiNameToFusiBaseStats;
    string[] public listOfFusiNames;

    struct FusiBaseStats {
        uint256 hp;
        uint256 atk;
        uint256 def;
        uint256 spa;
        uint256 spd;
        uint256 spe;
        string type1;
        string type2;
        uint256 number; 
        string fusiName;
    }

    constructor() abstract public {
        createBaseStatFusi(1,"Fissi1","Grass","Poison",318,45,49,49,65,65,45);
    }

    function createBaseStatFusi(uint256 number, string memory fusiName, string memory type1, string memory type2, uint256 hp, uint256 atk, uint256 def, uint256 spa, uint256 spd, uint256 spe) public onlyOwner {
        FusiBaseStats storage baseStats = fusiNameToFusiBaseStats[fusiName];
        baseStats.fusiName = fusiName;
        baseStats.type1 = type1;
        baseStats.type2 = type2;
        baseStats.number = number;
        baseStats.hp = hp; 
        baseStats.def = def;
        baseStats.atk = atk;
        baseStats.spa = spa;
        baseStats.spd = spd;
        baseStats.spe = spe;
        listOfFusiNames.push(fusiName);
    }

    function lengthOfListOfFusiNames() public view returns(uint256){
        return listOfFusiNames.length;
    }
}