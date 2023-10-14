// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/security/ReentrancyGuard.sol";

interface ILending {
    function toBurrow(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns (bool);
    function toRepay(uint16 srcChainId, bytes memory to, bytes memory token, uint256 amount) external returns (bool);
}
interface IBridge {
    function bridgeBurrow(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) external payable;
    function bridgeRepay(uint16 toChainId, bytes memory to, address currentTokenAddr, uint256 amount) external payable;
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
contract LendingMock is Ownable, ILending, ReentrancyGuard {
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
//    address public constant CCLP = 0x584911C7acB854ebA46E6c23e22CccF9E9e3D942;
    uint256 public constant INITIAL_APY = 100000; //1%
    constructor(uint16 test) {

    }
    event Supplied(address indexed user, address indexed token, uint256 amount);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    modifier onlyBridge() {
        require(
            msg.sender == address(bridge),
            "Only the bridge can call this."
        );
        _;
    }
    function burrow(
        uint16 toChainId,
        bytes memory to,
        address currentTokenAddr,
        uint256 amount
    ) external payable {
        require(currentTokenAddr != address(0), "Token address cannot be the zero address");
        require(_recoveryAddress(to) != address(0), "To address cannot be the zero address");
        require(userSupplied[currentTokenAddr][msg.sender] - userBurrowed[currentTokenAddr][msg.sender] >= amount, "Insufficient supply");
//        IERC20(currentTokenAddr).transfer(msg.sender, amount);
//        burrowApy[currentTokenAddr] += 50000;
//        supplyApy[currentTokenAddr] += 10000;
        totalBurrowed[currentTokenAddr] += amount;
        userBurrowed[currentTokenAddr][msg.sender] += amount;
        bridge.bridgeBurrow{value: msg.value}(toChainId, to, currentTokenAddr, amount);
        emit Borrowed(msg.sender, currentTokenAddr, amount);
    }
    function repay(
        uint16 toChainId,
        bytes memory to,
        address currentTokenAddr,
        uint256 amount
    ) external payable nonReentrant {
        require(currentTokenAddr != address(0), "Token address cannot be the zero address");
        require(_recoveryAddress(to) != address(0), "To address cannot be the zero address");
        require(amount <= userBurrowed[currentTokenAddr][msg.sender], "Repayment amount must less than borrowed amount");
        IERC20(currentTokenAddr).transferFrom(msg.sender, address(this), amount);
        if (burrowApy[currentTokenAddr] >= 50000) {
            burrowApy[currentTokenAddr] -= 50000;
        } else {
            burrowApy[currentTokenAddr] = 0;
        }
        if (supplyApy[currentTokenAddr] >= 10000) {
            supplyApy[currentTokenAddr] = 0;
        }
        totalBurrowed[currentTokenAddr] -= amount;
        userBurrowed[currentTokenAddr][msg.sender] -= amount;
        bridge.bridgeRepay{value: msg.value}(toChainId, to, currentTokenAddr, amount);
        emit Repaid(msg.sender, currentTokenAddr, amount);
    }

    function withdraw(address currentTokenAddr, uint256 amount) external {
        require(currentTokenAddr != address(0), "Token address cannot be the zero address");
        require(userSupplied[currentTokenAddr][msg.sender] >= amount, "Withdrawing more than supplied");
        IERC20(currentTokenAddr).transfer(msg.sender, amount);
        totalSupplied[currentTokenAddr] -= amount;
        userSupplied[currentTokenAddr][msg.sender] -= amount;
        supplyApy[currentTokenAddr] += 10000; // Increase of 1%
        emit Withdrawn(msg.sender, currentTokenAddr, amount);
    }

    function supply(address currentTokenAddr, uint256 amount) external {
        require(currentTokenAddr != address(0), "Token address cannot be the zero address");
        require(amount > 0, "Supply amount must be greater than zero");
        IERC20 token = IERC20(currentTokenAddr);

        token.transferFrom(msg.sender, address(this), amount);

        totalSupplied[currentTokenAddr] += amount;
        userSupplied[currentTokenAddr][msg.sender] += amount;
        if (supplyApy[currentTokenAddr] >= 10000) {
            supplyApy[currentTokenAddr] -= 10000;
        } else {
            supplyApy[currentTokenAddr] = 0;
        }
        emit Supplied(msg.sender, currentTokenAddr, amount);
    }
    function toBurrow(
        uint16 srcChainId,
        bytes memory to,
        bytes memory token,
        uint256 amount
    ) external onlyBridge returns (bool) {
        require(msg.sender == address(bridge), "must be bridge");
        address _to = _recoveryAddress(to);
        address _token = _recoveryAddress(token);
        IERC20(_token).transfer(_to, amount);
        totalBurrowed[_token] += amount;
        userBurrowed[_token][_to] += amount;
        burrowApy[_token] += 50000;
        supplyApy[_token] += 10000;
        return true;
    }
    function toRepay(
        uint16 srcChainId,
        bytes memory to,
        bytes memory token,
        uint256 amount
    ) external onlyBridge returns (bool) {
        require(msg.sender == address(bridge), "must be bridge");
        address _to = _recoveryAddress(to);
        address _token = _recoveryAddress(token);
        totalBurrowed[_token] -= amount;
        userBurrowed[_token][_to] -= amount;
//        burrowApy[_token] += 50000;
        return true;
    }
    function setBridge(address _bridge) external onlyOwner {
        bridge = IBridge(_bridge);
    }
    function registerToken(address token) external onlyOwner {
        supplyApy[token] = INITIAL_APY;
        burrowApy[token] = INITIAL_APY * 5;
    }
    function _recoveryAddress(
        bytes memory bytesAddr
    ) internal pure returns (address) {
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
}