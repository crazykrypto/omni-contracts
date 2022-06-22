// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/SafeArithmetics.sol";
import "../strategies/OmniCompoundStrategy.sol";
import "../token/Omni.sol";

contract OmniChef is OmniCompoundStrategy, Ownable {
    using SafeArithmetics for uint256;

    address public constant CEth = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    Omni public omni = new Omni("Omniscia Test Token", "OMNI", address(this));

    mapping(address => uint256) public times;
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;

    constructor() Ownable() OmniCompoundStrategy(CEth) {}

    // Prevent Renouncation & Transfer of Ownership
    function renounceOwnership() public override {
        revert("NO_OP");
    }

    function transferOwnership(address newOwner) public override {
        revert("NO_OP");
    }

    // Staking Mechanisms
    receive() external payable {
        require(stake(msg.value) != 0, "STAKING_MALFUNCTION");
    }

    function stake() external payable returns (uint256) {
        return stake(msg.value);
    }

    function stake(uint256 value)
        public
        payable
        refund(value)
        returns (uint256)
    {
        stakes[msg.sender] = stakes[msg.sender].safe(
            SafeArithmetics.Operation.ADD,
            value
        );
        times[msg.sender] = block.timestamp;
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.ADD, value);

        return stakes[msg.sender];
    }

    function withdraw(uint256 value) external returns (uint256 amount) {
        require(stakes[msg.sender] >= value, "INSUFFICIENT_STAKE");

        amount = stakes[msg.sender]
            .safe(SafeArithmetics.Operation.MUL, balance())
            .safe(SafeArithmetics.Operation.DIV, totalStakes);

        stakes[msg.sender] = stakes[msg.sender].safe(
            SafeArithmetics.Operation.SUB,
            value
        );
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.SUB, value);

        _unlock(amount);
        _reward(value);
    }

    // Linear time based rewards
    function _reward(uint256 stake) internal {
        uint256 reward = stake * (block.timestamp - times[msg.sender]);

        if (reward > omni.balanceOf(address(this)))
            reward = omni.balanceOf(address(this));

        if (reward != 0) omni.transfer(msg.sender, reward);

        times[msg.sender] = 0;
    }

    modifier refund(uint256 value) {
        _;

        // Refund any excess ether sent to the contract
        if (msg.value > value)
            _send(
                payable(msg.sender),
                msg.value.safe(SafeArithmetics.Operation.SUB, value)
            );
    }
}
