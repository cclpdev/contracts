// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface IBridge {
    function bridgeBurrow(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external;

    function bridgeRepay(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external;
}