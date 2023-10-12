// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/Token.sol";

contract TokenTest is Test {
    DAOToken t;

    function setUp() public {
        t = new DAOToken(200);
    }

    function testName() public {
        assertEq(t.name(), "DAO Token");
    }
}
