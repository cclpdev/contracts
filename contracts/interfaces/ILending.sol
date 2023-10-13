// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;


interface ILending {
    function toBurrow(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns(bool);

    function toRepay(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns(bool);
}