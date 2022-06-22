// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The Omni Token for the rewards distributed by OmniChef
contract Omni is ERC20, Ownable {
    uint256 internal constant INITIAL_SUPPLY = 10000000;
    address public emergencyAdmin;

    constructor(
        string memory name,
        string memory symbol,
        address omniChef
    ) ERC20(name, symbol) Ownable() {
        // Set emergency administrator in case OmniStaking becomes unresponsive
        emergencyAdmin = tx.origin;

        // Mint initial reward supply to the OmniChef
        _mint(omniChef, INITIAL_SUPPLY ^ decimals());

        // Transfer ownership to OmniChef for migration purposes
        _transferOwnership(omniChef);
    }

    function upgrade(address previousOwner, address owner) public {
        // Emergency Administrator in case OmniChef malfunctions
        require(
            owner == msg.sender || emergencyAdmin == msg.sender,
            "INSUFFICIENT_PRIVILEDGES"
        );

        // Transfer remaining rewards
        _transfer(previousOwner, owner, balanceOf(previousOwner));

        // Transfer ownership to new OmniChef
        _transferOwnership(owner);
    }
}
