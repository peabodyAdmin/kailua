// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IRiscZeroVerifier} from "@kailua/contracts/src/lib.rs";

/**
 * @title L1Commits
 * @notice Minimal L1 commitment contract for Eclipse L2 rollup
 * @dev This contract demonstrates the core mechanisms for state commitments and dispute resolution
 */
contract L1Commits {
    // CORE STATE VARIABLES
    // ==========================================

    /// @notice Struct to represent a state commitment
    struct Commitment {
        bytes32 stateRoot;           // Root hash representing L2 state
        uint256 blockNumber;          // Block number of the commitment
        uint256 timestamp;            // Timestamp of commitment
        address proposer;             // Address that proposed the commitment
        bool disputed;                // Whether the commitment is under dispute
    }

    // ECONOMIC DESIGN PARAMETERS
    // ==========================================

    /// @notice Minimum stake required to propose a commitment
    /// @dev TEAM DECISION: What is the appropriate stake amount?
    uint256 public constant MIN_STAKE = 0.1 ether;

    /// @notice Dispute challenge period
    /// @dev TEAM DECISION: How long should challengers have to dispute?
    uint256 public constant CHALLENGE_PERIOD = 7 days;

    /// @notice Reward for successful dispute
    /// @dev TEAM DECISION: What percentage of stake should be rewarded?
    uint256 public constant DISPUTE_REWARD_PERCENTAGE = 50;

    // STATE TRACKING
    // ==========================================

    /// @notice Mapping of block numbers to commitments
    mapping(uint256 => Commitment) public commitments;

    /// @notice Tracks total stakes for each proposer
    mapping(address => uint256) public stakes;

    /// @notice Verifier contract for zero-knowledge proofs
    /// @dev TEAM DECISION: Which specific verifier will be used?
    IRiscZeroVerifier public immutable verifier;

    // EVENTS
    // ==========================================

    /// @notice Emitted when a new commitment is proposed
    event CommitmentProposed(
        uint256 indexed blockNumber, 
        bytes32 stateRoot, 
        address proposer
    );

    /// @notice Emitted when a commitment is disputed
    event CommitmentDisputed(
        uint256 indexed blockNumber, 
        address challenger
    );

    // CONSTRUCTOR
    // ==========================================

    /// @notice Initialize the contract with a verifier
    /// @dev TEAM DECISION: Determine the specific verifier implementation
    constructor(address _verifier) {
        verifier = IRiscZeroVerifier(_verifier);
    }

    // COMMITMENT PROPOSAL
    // ==========================================

    /**
     * @notice Propose a new state commitment
     * @param _stateRoot Root hash of the L2 state
     * @param _proof Zero-knowledge proof of state transition
     * 
     * @dev TEAM DECISIONS TO MAKE:
     * 1. Proof validation strategy
     * 2. Stake requirements
     * 3. Commitment acceptance criteria
     */
    function proposeCommitment(
        bytes32 _stateRoot, 
        bytes memory _proof
    ) external payable {
        // TEAM DECISION: Stake validation logic
        require(msg.value >= MIN_STAKE, "Insufficient stake");

        // TEAM DECISION: Proof verification strategy
        // How will we validate the proof from the research team?
        bool isProofValid = verifier.verify(_proof);
        require(isProofValid, "Invalid state transition proof");

        // Create and store commitment
        Commitment memory newCommitment = Commitment({
            stateRoot: _stateRoot,
            blockNumber: block.number,
            timestamp: block.timestamp,
            proposer: msg.sender,
            disputed: false
        });

        commitments[block.number] = newCommitment;
        stakes[msg.sender] += msg.value;

        emit CommitmentProposed(block.number, _stateRoot, msg.sender);
    }

    // DISPUTE RESOLUTION
    // ==========================================

    /**
     * @notice Challenge a proposed commitment
     * @param _blockNumber Block number of the commitment being challenged
     * @param _disputeProof Proof demonstrating the commitment's invalidity
     * 
     * @dev TEAM DECISIONS TO MAKE:
     * 1. Dispute proof validation
     * 2. Economic penalties
     * 3. Reward mechanism
     */
    function disputeCommitment(
        uint256 _blockNumber, 
        bytes memory _disputeProof
    ) external {
        Commitment storage commitment = commitments[_blockNumber];

        // Validate dispute timing
        require(
            block.timestamp <= commitment.timestamp + CHALLENGE_PERIOD, 
            "Challenge period expired"
        );
        require(!commitment.disputed, "Commitment already disputed");

        // TEAM DECISION: Dispute proof validation
        // How will the research team provide dispute proofs?
        bool isDisputeValid = verifier.verify(_disputeProof);
        require(isDisputeValid, "Invalid dispute proof");

        // Mark commitment as disputed
        commitment.disputed = true;

        // Calculate and distribute rewards
        uint256 disputeReward = (stakes[commitment.proposer] * DISPUTE_REWARD_PERCENTAGE) / 100;
        
        // TEAM DECISION: Implement precise slashing and reward mechanisms
        payable(msg.sender).transfer(disputeReward);
        
        emit CommitmentDisputed(_blockNumber, msg.sender);
    }

    // UTILITY FUNCTIONS
    // ==========================================

    /**
     * @notice Retrieve the latest valid commitment
     * @return The most recent non-disputed commitment
     * 
     * @dev TEAM DECISION: Define "latest valid" precisely
     */
    function getLatestValidCommitment() external view returns (Commitment memory) {
        // TEAM DECISION: Implement logic to find most recent valid commitment
        // This is a placeholder implementation
        for (uint256 i = block.number; i > 0; i--) {
            Commitment memory commitment = commitments[i];
            if (!commitment.disputed) {
                return commitment;
            }
        }
        revert("No valid commitment found");
    }
}