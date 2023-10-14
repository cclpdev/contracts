// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/ILending.sol";
import "../interfaces/IBridge.sol";
pragma abicoder v2;

contract LendingMock is ILending {
    IBridge public bridge;
    // totalSupplied[tokenAddr] = amount
    mapping(address => uint256) public totalSupplied;
    // totalBurrowed[tokenAddr] = amount
    mapping(address => uint256) public totalBurrowed;
    // userSupplied[tokenAddr][userAddr] = amount
    mapping(address => mapping(address => uint256)) public userSupplied;
    // userBurrowed[tokenAddr][userAddr] = amount
    mapping(address => mapping(address => uint256)) public userBurrowed;
    // supplyApy[tokenAddr] = apy, real apy = apy / 1000000
    mapping(address => uint256) public supplyApy;
    // burrowApy[tokenAddr] = apy, real apy = apy / 1000000
    mapping(address => uint256) public burrowApy;
    constructor(uint256 test) {
    }

    function burrow(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external {
        bridge.bridgeBurrow(toChainId, to, currentTokenAddr, amount);
    }

    function repay(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external {
        bridge.bridgeRepay(toChainId, to, currentTokenAddr, amount);
    }

    function withdraw(address currentTokenAddr, uint256 amount) external {

    }

    function supply(address currentTokenAddr, uint256 amount) external {

    }

    function toBurrow(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns(bool) {
        return true;
    }

    function toRepay(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns(bool) {
        return true;
    }

    function setBridge(address _bridge) external {
        bridge = IBridge(_bridge);
    }
}