// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// import {ERC20} from "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAOToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DAO Token", "DAO") {
        _mint(msg.sender, initialSupply);
    }
}