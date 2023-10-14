// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./openzeppelin/utils/math/SafeMath.sol";
import "./openzeppelin/security/ReentrancyGuard.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/access/Ownable.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/ILending.sol";
import "./interfaces/IBridge.sol";
import "./CPToken.sol";
import "./function/FeeDonate.sol";

contract Bridge is ILayerZeroReceiver, ILayerZeroUserApplicationConfig, ReentrancyGuard, Ownable, IBridge {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct LzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    using SafeMath for uint256;
    //---------------------------------------------------------------------------
    // type
    uint8 TypeBridgeBurrow = 0;
    uint8 TypeBridgeRepay = 1;
    //---------------------------------------------------------------------------
    uint64 public nonce = 0;

    //---------------------------------------------------------------------------
    // bridgeTokenMap[toChainId][currentChainTokenAddr] = targetChainTokenBytes
    mapping(uint16 => mapping(address => bytes)) public bridgeTokenMap;
    // srcChainNonceMap[srcChainId][nonce] = 0/1
    mapping(uint16 => mapping(uint64 => uint8)) public srcChainNonceMap;
    // lZeroNonceMap[srcChainId][_srcAddress][nonceLZero] = 1/0
    mapping(uint16 => mapping(bytes => mapping(uint64 => uint8))) public lZeroNonceMap;
    //---------------------------------------------------------------------------
    // VARIABLES
    ILayerZeroEndpoint public immutable layerZeroEndpoint;
//    ILending public immutable lending;
    ILending public lending;

    // Record toChainID and remote address and local address
    // bridgeLookup[toChainID] = remote+local
    mapping(uint16 => bytes) public bridgeLookup;
    mapping(uint16 => mapping(uint8 => uint256)) public gasLookup;

    //---------------------------------------------------------------------------
    // EVENTS
    event SendMsg(uint8 msgType, uint64 nonce);

    constructor(address _layerZeroEndpoint, address _lending) {
        require(_layerZeroEndpoint != address(0x0));
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        lending = ILending(_lending);
    }

    receive() external payable {
//        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    //---------------------------------------------------------------------------
    // EXTERNAL functions
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override nonReentrant {
        // just support EVM
        require(msg.sender == address(layerZeroEndpoint), "118");
        require(
            _srcAddress.length == bridgeLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(bridgeLookup[_srcChainId]),
            "119"
        );
        uint8 actionType;
        assembly {
            actionType := mload(add(_payload, 32))
        }

        if (actionType == TypeBridgeBurrow) {
            _receiveBridgeBurrow(_srcChainId, _nonce, _srcAddress, _payload);
        } else if (actionType == TypeBridgeRepay) {
            _receiveBridgeRepay(_srcChainId, _nonce, _srcAddress, _payload);
        }
    }

    //---------------------------------------------------------------------------
    // Internal functions
    function _receiveBridgeBurrow(uint16 _srcChainId, uint64 _nonce, bytes memory _srcAddress, bytes memory _payload) internal {
        (, bytes memory to, bytes memory token, uint256 burrowAmount, uint64 nonceSrc) = abi.decode(_payload, (uint8, bytes, bytes, uint256, uint64));
        // require and use valid nonce
        _requireAndUseValidNonce(_srcChainId, _srcAddress, nonceSrc, _nonce);
        bool result = lending.toBurrow(_srcChainId, to, token, burrowAmount);
        if (!result) {
            // TODO
        }
    }

    function _receiveBridgeRepay(uint16 _srcChainId, uint64 _nonce, bytes memory _srcAddress, bytes memory _payload) internal {
        (, bytes memory to, bytes memory token, uint256 burrowAmount, uint64 nonceSrc) = abi.decode(_payload, (uint8, bytes, bytes, uint256, uint64));
        // require and use valid nonce
        _requireAndUseValidNonce(_srcChainId, _srcAddress, nonceSrc, _nonce);
        bool result = lending.toRepay(_srcChainId, to, token, burrowAmount);
        if (!result) {
            // TODO
        }
    }

    function _requireAndUseValidNonce(uint16 _srcChainId, bytes memory _srcAddress, uint64 nonceSrc, uint64 _nonce) internal {
        require(srcChainNonceMap[_srcChainId][nonceSrc] == 0, "120");
        require(lZeroNonceMap[_srcChainId][_srcAddress][_nonce] == 0, "121");
        // use nonce
        srcChainNonceMap[_srcChainId][nonceSrc] = 1;
        // use nonceLZero
        lZeroNonceMap[_srcChainId][_srcAddress][_nonce] = 1;
    }

    function _recoveryAddress(bytes memory bytesAddr) internal pure returns(address) {
//        require(bytesAddr.length == 20, "Invalid bytes length");
        if (bytesAddr.length != 20) {
            return address(0x0);
        }
        address addr;
        assembly {
            addr := mload(add(bytesAddr, 20))
        }
        return addr;
    }

    //---------------------------------------------------------------------------
    // LOCAL CHAIN FUNCTIONS
    function bridgeBurrow(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external {
        require(msg.sender == address(lending), "no access");
        LzTxObj memory adapterParams;
        require(currentTokenAddr != address(0x0), "token can not be 0x0");
        require(_recoveryAddress(to) != address(0x0), "to can not be 0x0");
        // check bridge map
        require(bridgeTokenMap[toChainId][currentTokenAddr].length != 0, "need register token");
        require(msg.value > 0, "must provide value");
        _callSend(msg.value, toChainId, TypeBridgeBurrow, adapterParams, abi.encode(TypeBridgeBurrow, to, bridgeTokenMap[toChainId][currentTokenAddr], amount, _getNextNonce()));
    }

    function bridgeRepay(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) payable external {
        require(msg.sender == address(lending), "no access");
        LzTxObj memory adapterParams;
        require(currentTokenAddr != address(0x0), "token can not be 0x0");
        require(_recoveryAddress(to) != address(0x0), "to can not be 0x0");
        // check bridge map
        require(bridgeTokenMap[toChainId][currentTokenAddr].length != 0, "need register token");
        _callSend(msg.value, toChainId, TypeBridgeRepay, adapterParams, abi.encode(TypeBridgeRepay, to, bridgeTokenMap[toChainId][currentTokenAddr], amount, _getNextNonce()));
    }

    //---------------------------------------------------------------------------
    // internal functions
    function _getNextNonce() internal returns(uint64) {
        nonce += 1;
        return nonce;
    }

    function _txParamBuilderType1(uint256 gasAmount) internal pure returns (bytes memory) {
        uint16 txType = 1;
        return abi.encodePacked(txType, gasAmount);
    }

    function _txParamBuilderType2(uint256 gasAmount, uint256 dstNativeAmount, bytes memory dstNativeAddr) internal pure returns (bytes memory) {
        uint16 txType = 2;
        return abi.encodePacked(txType, gasAmount, dstNativeAmount, dstNativeAddr);
    }

    function _txParamBuilder(uint16 toChainId, uint8 actionType, LzTxObj memory lzTxParams) internal view returns (bytes memory) {
        bytes memory adapterParams;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }
        uint256 totalGas = gasLookup[toChainId][actionType].add(lzTxParams.dstGasForCall);
        if (lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            adapterParams = _txParamBuilderType2(totalGas, lzTxParams.dstNativeAmount, lzTxParams.dstNativeAddr);
        } else {
            adapterParams = _txParamBuilderType1(totalGas);
        }
        return adapterParams;
    }

    function _callSend(uint256 leftBalance, uint16 toChainId, uint8 actionType, LzTxObj memory lzTxParams, bytes memory payload) internal  {
        bytes memory lzTxParamBuilt = _txParamBuilder(toChainId, actionType, lzTxParams);
        layerZeroEndpoint.send{value: leftBalance}(toChainId, bridgeLookup[toChainId], payload, payable(address(this)), address(this), lzTxParamBuilt);
        emit SendMsg(actionType, layerZeroEndpoint.getOutboundNonce(toChainId, address(this)) + 1);
    }

    //---------------------------------------------------------------------------
    // DAO config set
    function registerTokenMap(uint16 toChainId, address currentTokenAddress, bytes memory targetTokenBytes) external onlyOwner {
        // TODO
//        require(bridgeTokenMap[toChainId][currentTokenAddress].length == 0, "had register");
        bridgeTokenMap[toChainId][currentTokenAddress] = targetTokenBytes;
    }

    function setBridge(uint16 toChainId, bytes calldata bridgeAddress) external onlyOwner {
        // so nice
        // TODO test
//        require(bridgeLookup[toChainId].length == 0, "Bridge already set!");
        bridgeLookup[toChainId] = bridgeAddress;
    }

    function setGasAmount(uint16 toChainId, uint8 actionType, uint256 gasAmount) external onlyOwner {
        gasLookup[toChainId][actionType] = gasAmount;
    }

    function setLending(address _lending) external onlyOwner {
        lending = ILending(_lending);
    }

    //---------------------------------------------------------------------------
    // Interface Function
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // generic config for user Application
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyOwner {
        layerZeroEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }
}