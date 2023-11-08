// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MyContract {

    // Mapping with a struct as its value
   using EnumerableSet for EnumerableSet.AddressSet;


    mapping(uint => MyStruct) public structMap;



    // Struct that is used as the value in the mapping

    struct MyStruct {
        uint a;
        uint b;
        uint[] arr;
    }



    // Public function that returns the value of the struct at a given index in the mapping

    function getStruct(uint index) public view returns (uint, uint) {
        MyStruct memory s = structMap[index];
        return (s.a, s.b);
    }
}