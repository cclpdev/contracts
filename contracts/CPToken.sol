// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
interface Token{
    function totalSupply() external returns (uint256);

    function balanceOf(address _owner) external returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 total;

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() external view returns (uint256) {
        return total;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CPToken is StandardToken {

    /* Public variables of the token */
    string public name;
    uint8 public decimals;
    string public symbol;
    uint16 public srcChainId;
    address public srcTokenAddr;
    address public admin;

    constructor(uint16 _srcChainId, address _srcTokenAddr, string memory _tokenName, uint8 _decimals) {
        srcChainId = _srcChainId;
        srcTokenAddr = _srcTokenAddr;
        balances[msg.sender] = 0;
        total = 0;
        name = _tokenName;
        decimals = _decimals;
        symbol = _tokenName;
        admin = msg.sender;
    }

    function mint(uint256 amount, address to) external {
        require(msg.sender == admin);
        total += amount;
        balances[to] += amount;
        emit Transfer(address(0x0), to, amount);
    }

    function burn(uint256 amount, address from) external {
        require(msg.sender == admin);
        require(from != address(0x0));
        total -= amount;
        balances[from] -= amount;
        emit Transfer(from, address(0x0), amount);
    }

    // ######### Admin
    function rescueToken(address token, uint256 value) external {
        require(msg.sender == admin);
        Token(token).transfer(msg.sender, value);
    }

    function rescue() external {
        require(msg.sender == admin);
        payable(msg.sender).transfer(address(this).balance);
    }

}