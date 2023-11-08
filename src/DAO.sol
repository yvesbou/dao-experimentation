// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DAOToken } from "./Token.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAO is Ownable {
    // Event for a new proposal
    event NewProposal(uint256 indexed proposalId, address indexed proposer, string description);
    // Event for a proposal execution
    event ProposalExecuted(uint256 indexed proposalId, address indexed proposer, address indexed recipient, uint256 amount);

    // The DAO token contract
    DAOToken public daoToken;

    // source: https://docs.openzeppelin.com/contracts/3.x/api/utils#EnumerableSet
    using EnumerableSet for EnumerableSet.AddressSet;

    // The minimum amount of tokens required to create a proposal
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 1000 * 10**18;

    // The minimum amount of tokens required to vote on a proposal
    uint256 public constant MIN_VOTING_THRESHOLD = 100 * 10**18;

    // Proposal struct
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        address payable recipient;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        EnumerableSet.AddressSet voters;
        bool executed;
    }

    // Array of all proposals
    // has to be private: https://failureaid.com/solidity-internal-or-recursive-type-is-not-allowed-for-public-state-variables-cannot-expose-public-mapping-containing-struct/
    // therefore getProposal which deconstructs the array elements
    Proposal[] private proposals;
    // setup with 0 (by default)
    uint private numProposals;

    // Mapping to check if an address has an active proposal
    mapping(address => bool) public activeProposals;

    constructor(address _daoToken, address _owner) Ownable(_owner) {
        daoToken = DAOToken(_daoToken);
    }
    
    // Types containing (nested) mappings can only be parameters or return variables of internal or library functions.
    function getProposal(uint index) public view returns (uint256, address, string memory, uint256, address, uint256, uint256, uint256, uint256, address[] memory, bool) {
        Proposal storage p = proposals[index];
        address[] memory voters = new address[](p.voters.length());
        for (uint256 j = 0; j < p.voters.length(); j++) {
            // voters[j] = EnumerableSet.at(p.voters, index);
            voters[j] = p.voters.at(index);
        }

        return (
            p.id,
            p.proposer,
            p.description,
            p.amount,
            p.recipient,
            p.startTime,
            p.endTime,
            p.yesVotes,
            p.noVotes,
            voters,
            p.executed
        );
    }
    

    // Function to create a new proposal
    function createProposal(string memory _description, uint256 _amount, address payable _recipient) external {
        require(daoToken.balanceOf(msg.sender) >= MIN_PROPOSAL_THRESHOLD, "Insufficient tokens to create proposal");
        require(!activeProposals[msg.sender], "You already have an active proposal");
        // EnumerableSet.AddressSet memory set = new EnumerableSet.AddressSet;  doesn't work
        // EnumerableSet.AddressSet storage sets; works
        // EnumerableSet.AddressSet memory addresses = EnumerableSet.add(EnumerableSet.AddressSet, address(0));  doesn't work
        
        proposals.push();
        uint id = proposals.length-1;
        Proposal storage p = proposals[id];
        
        p.id = proposals.length;
        p.proposer = msg.sender;
        p.description = _description;
        p.amount = _amount;
        p.recipient = _recipient;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + 7 days;
        p.yesVotes = 0;
        p.noVotes = 0;
        // p.voters = sets; // no needed to initialise
        p.executed = false;

        activeProposals[msg.sender] = true;
        emit NewProposal(id, msg.sender, _description);

        // p.voters.add(address(0));
        // open Q: what happens with voters inside the proposal struct and how could I instantiate it inside a struct?
        
        // Proposal memory newProposal = Proposal({
        //     id: proposals.length,
        //     proposer: msg.sender,
        //     description: _description,
        //     amount: _amount,
        //     recipient: _recipient,
        //     startTime: block.timestamp,
        //     endTime: block.timestamp + 7 days,
        //     yesVotes: 0,
        //     noVotes: 0,
        //     voters: sets,
        //     executed: false
        // });
    }

    // open Q: is require the best way to check?
    // open Q: when storage and when memory?
    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _support) external {
        uint256 voterWeight = daoToken.balanceOf(msg.sender);
        require(voterWeight >= MIN_VOTING_THRESHOLD, "Insufficient tokens to vote");
        
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Invalid voting period");
        require(!proposal.voters.contains(msg.sender), "You have already voted on this proposal");
        
        if (_support) {
            proposal.yesVotes += voterWeight;
        } else {
            proposal.noVotes += voterWeight;
        }

        proposal.voters.add(msg.sender);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp > proposal.endTime, "Voting period is still ongoing");
        require(proposal.yesVotes > proposal.noVotes, "Proposal has not reached majority support");

        proposal.executed = true; // before to prevent re-entrancy
        activeProposals[proposal.proposer] = false;
        proposal.recipient.transfer(proposal.amount); // how does this work?
        emit ProposalExecuted(_proposalId, proposal.proposer, proposal.recipient, proposal.amount);
    }

    // Function to withdraw funds from the DAO
    function withdraw(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    // Fallback function to accept Ether
    receive() external payable {}

}