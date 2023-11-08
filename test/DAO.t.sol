// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/Token.sol";
import "../src/DAO.sol";

contract DAOTest is Test {
    DAOToken token;
    DAO dao;
    address daoOwner;
    address payable beneficiary;

    function setUp() public {
        daoOwner = vm.addr(1);
        beneficiary = payable(vm.addr(2));
        vm.prank(daoOwner);
        token = new DAOToken(1_000_000*10**18);
        vm.deal(daoOwner, 100 ether);
        vm.prank(daoOwner);
        dao = new DAO(address(token), daoOwner);
    }

    function testOwner() public {
        assertEq(dao.owner(), daoOwner);
    }

    function testBalanceOwner() public {
        assertEq(token.balanceOf(daoOwner), 1_000_000*10**18);
    }

    function testCreateProposal() public {
        vm.prank(daoOwner);
        dao.createProposal("my first proposal", 1 ether, beneficiary);
        (
            uint256 id,
            address proposer,
            string memory description,
            uint256 amount,
            address recipient,
            uint256 startTime,
            uint256 endTime,
            uint256 yesVotes,
            uint256 noVotes,
            address[] memory voters,
            bool executed
        )   = dao.getProposal(0);
        assertEq(proposer, daoOwner);
        assertEq(recipient, beneficiary);
        assertEq(amount, 1 ether);
        assertEq(description, "my first proposal");
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
        assertEq(executed, false);
    }

    function testExecutedProposal() public {
        vm.deal(address(dao), 10 ether);

        vm.prank(daoOwner);
        dao.createProposal("my first proposal", 1 ether, beneficiary);

        vm.prank(daoOwner);
        dao.vote(0, true);

        vm.warp(7 days + 1 minutes);

        vm.prank(daoOwner);
        dao.executeProposal(0);

        assertEq(address(beneficiary).balance, 1 ether);
    }
}
