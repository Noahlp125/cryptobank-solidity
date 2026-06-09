//License
//-SPDX-License-Identifier: LGPL-3.0-only 
 pragma solidity 0.8.24;

//Title: ALP Token-ERC-20 for CryptoBank
//Mintable and burnable token, controlled excluxively by the bank
 //Contract
 contract CryptoBank_token {
//State Variables
string public name="ALP Token";
string public symbol="ALP";
uint8 public decimals=18;
uint256 public TotalSupply;

address public bank; //bank contract address

mapping (address => uint256) public balanceOf;
mapping (address=>mapping (address=>uint256)) public allowance;

//----------
//Events
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner,address indexed spender, uint256 value);
event BankUpdated(address indexed newBank);
//-------
//Modifiers
modifier onlyBank(){
    if (msg.sender !=bank) revert ("Solo el banco puede ejecutar esto");
    _;
}

//---------
//Constructor
constructor(){
    bank= msg.sender; 
}
//---------
//Configuration 
//Updates the bank address — it is called once upon CryptoBank deployment
function setBank(address newBank_) external {
    if (msg.sender != bank) revert ("No autorized");
    if (newBank_== address(0)) revert ("Invalid direction");
    bank=newBank_;
    emit BankUpdated(newBank_);
}
//........
//Estandar ERC-20 functions
//Transfer tokens to another address
function transfer(address to_, uint256 amount_) external returns (bool) {
    if (to_== address(0)) revert ("Invalid Direction");
    if (balanceOf[msg.sender] < amount_) revert("Saldo insuficiente");

        balanceOf[msg.sender] -= amount_;
        balanceOf[to_] += amount_;

        emit Transfer(msg.sender, to_, amount_);
        return true;
}

//Approve another address to spend tokens on your behalf
function approve (address spender_, uint256 amount_) external returns (bool){
    if (spender_==address(0)) revert ("Invalid address");
    allowance[msg.sender][spender_]= amount_;
    emit Approval(msg.sender, spender_, amount_);
    return true;
}

//Transfers tokens from another address (requires prior approval)
function transferFrom (address from_, address to_, uint256 amount_) external returns (bool) {
    if (to_==address(0)) revert ("Invalid address");
    if (balanceOf[from_]< amount_) revert ("Insuficient Balance");
    if (allowance[from_][msg.sender]<amount_) revert ("Insufficient allowance");

    allowance[from_][msg.sender] -= amount_;
    balanceOf[from_] -=amount_;
    balanceOf[to_]+=amount_;

    emit Transfer(from_, to_, amount_);
    return true;
}
//..............
//Mint and burn-only bank
//Mints new tokens-only the bank can call this
function mint(address to_, uint256 amount_) external onlyBank {
    if (to_== address(0)) revert ("Invalid address");
    TotalSupply +=amount_;
    balanceOf[to_]+=amount_;
    emit Transfer(address(0), to_, amount_);
}

//Burns tokens- only the bank can call this
function burn (address from_, uint256 amount_) external onlyBank {
    if (balanceOf[from_]< amount_) revert ("Insufficient balance");
    balanceOf[from_] -=amount_;
    TotalSupply-=amount_;
    emit Transfer( from_, address(0), amount_);
}
 }