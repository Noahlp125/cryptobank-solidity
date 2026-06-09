// SPDX-License-Identifier: LGPL-3.0-only
 pragma solidity 0.8.24;

 import "artifacts/CryptoBank_token.sol";

 //CryptoBank-Decentralized bank using ALP Token
 //Deposit ETH, receive ALP tokens. Withdraw, earn interest and request loans.
 contract CryptoBank {
//..........
//State Variables
address public owner;
bool public paused;

CryptoBank_token public token;

uint256 public constant TOKENS_PER_ETH = 1000; //1 ETH= 1000 ALP
uint256 public constant INTEREST_RATE= 5; //5% annual interest
uint256 public constant LOAN_INTEREST_RATE= 10;//10% annual interest
uint256 public constant COLLATERAL_RATIO=150; //150% collateral required
uint256 public constant DAILY_WITHDRAWAL_LIMIT= 1 ether;
uint256 public constant SECONDS_PER_YEAR=365 days;
//...........
//Structs
struct Account {
    uint256 ethDeposited; //ETH deposited by user
    uint256 alpBalance; //ALP tokens minted to user
    uint256 depositTimestamp; //when user last deposited 
    uint256 lastWithdrawal; //timestamp of last withdrawal
    uint256 withdrawnToday; //amount withdrawn today
}

struct Loan {
    uint256 alpBorrowed; //ALP tokens borrowed
    uint256 ethCollateral; //ETH locked as collateral
    uint256 loanTimestamp; //when loan was taken
    bool active; //wheter loan is active
}
//.............
//Mappings 
mapping (address => Account) public accounts;
mapping (address => Loan) public loans;
mapping (address => bool) public admins;

//.............
//Events
event Deposited(address indexed user, uint256 ethAmount, uint256 alpMinted);
event Withdrawn(address indexed user, uint256 alpBurned, uint256 ethReturned);
event InterestClaimed(address indexed user, uint256 alpAmount);
event LoanTaken(address indexed user, uint256 alpBorrowed, uint256 ethCollateral);
event LoanRepaid(address indexed user, uint256 alpRepaid, uint256 ethReturned);
event AdminAdded(address indexed admin);
event AdminRemoved(address indexed admin);
event Paused (address indexed by);
event Unpaused (address indexed by);

//.............
//Modifiers 
modifier onlyOwner() {
    if (msg.sender != owner) revert ("only owner");
    _; 
}

modifier onlyAdmin() {
    if (msg.sender != owner && !admins[msg.sender]) revert ("Only Admin or Owner");
    _;
}

modifier notPaused() {
    if (paused) revert ("Contract is paused");
    _;
}

modifier noActiveLoan() {
    if (loans[msg.sender].active) revert ("Repay your loan first");
    _;
}

//..............
//Constructor
// tokenAddress_ address of the deployed CryptoBank_token contract
constructor(address tokenAddress_) {
    if (tokenAddress_ == address(0)) revert ("Invalid token address");
    owner=msg.sender;
    token= CryptoBank_token (tokenAddress_);
}

//...........
//Owner functions
//Adds a new admin
function addAdmin(address admin_) external onlyOwner {
    if(admin_ == address(0)) revert ("Invalid address");
    admins[admin_] =true;
    emit AdminAdded(admin_);
}
//Removes an admin
function removeAdmin(address admin_) external onlyOwner {
    admins[admin_]= false;
    emit AdminRemoved(admin_);
}
//Pauses the contract-no deposits, withdrawls or loans
function pause() external onlyOwner{
    if (paused) revert ("Alredy paused");
    paused=true;
    emit AdminRemoved(msg.sender);
}
//Unpauses the contract
function unpause() external onlyAdmin {
    if (!paused) revert ("Not paused");
    emit Unpaused(msg.sender);
}
//...........
//Core functions
//Deposit ETH and receive ALP tokens
function deposit () external payable notPaused {
    if (msg.value == 0) revert ("Must send ETH");
    uint256 alpToMint= msg.value * TOKENS_PER_ETH;
    accounts[msg.sender].ethDeposited +=msg.value;
    accounts[msg.sender].alpBalance += alpToMint;
    accounts[msg.sender].depositTimestamp = block.timestamp;

    token.mint(msg.sender, alpToMint);
    emit Deposited(msg.sender, msg.value, alpToMint);
} 

//Burn ALP tokens and receive ETH back
function withdraw (uint256 alpAmount_) external notPaused noActiveLoan {
    if (alpAmount_==0) revert ("Amount must be greater than zero");
    if (token.balanceOf(msg.sender)< alpAmount_) revert ("Insufficient ALP balance");

    uint256 ethToReturn= alpAmount_/ TOKENS_PER_ETH;
    if (address(this).balance < ethToReturn) revert ("Insufficient bank liquidity");
    //Daily withdrawal limit check
    if (block.timestamp /1 days > accounts[msg.sender].lastWithdrawal /1 days){
        accounts[msg.sender].withdrawnToday=0;
    }
    if (accounts[msg.sender].withdrawnToday + ethToReturn> DAILY_WITHDRAWAL_LIMIT) {
        revert ("Daily withdrawal limit exceeded");
    }

    //CHECK- update state before external calls
    accounts [msg.sender].ethDeposited -= ethToReturn;
    accounts [msg.sender].alpBalance -= alpAmount_;
    accounts [msg.sender].withdrawnToday += ethToReturn;
    accounts [msg.sender].lastWithdrawal = block.timestamp;

    //EFECT- burn tokens
    token.burn (msg.sender, alpAmount_);

    //INTERACTION- send ETH last
    (bool ok, )= msg.sender.call {value: ethToReturn}("");
    if (!ok) revert ("ETH transfer failed");

    emit Withdrawn(msg.sender, alpAmount_, ethToReturn);
}

//Claimed accumulated interest in ALP tokens
function claimInterest() external notPaused {
    uint256 deposited= accounts[msg.sender].ethDeposited;
    if (deposited==0) revert("No deposit found");

    uint256 timeElapsed= block.timestamp- accounts[msg.sender].depositTimestamp;
    if (timeElapsed==0) revert ("No interest accred yet");

    //interest=deposited*rate*time/year/100
    uint256 interestInEth= (deposited * INTEREST_RATE * timeElapsed)/(SECONDS_PER_YEAR * 100);
    uint256 interestInAlp= interestInEth * TOKENS_PER_ETH;
    if (interestInAlp==0) revert ("Interest too small to claim");
    //Reset timestamp after claiming
    accounts[msg.sender].depositTimestamp= block.timestamp;
    token.mint(msg.sender, interestInAlp);
    emit InterestClaimed(msg.sender, interestInAlp);
}

//Take a loan in ALP tokens by locking ETH as a collateral
function takeLoan(uint256 alpAmount_) external payable notPaused {
    if (alpAmount_==0) revert ("Amount must be greater than zero");
    if (loans [msg.sender].active) revert ("You alredy have an active loan");

    //Required collateral: 150% of loan value in ETH
    uint256 ethRequired= (alpAmount_* COLLATERAL_RATIO) / (TOKENS_PER_ETH*100);
    if (msg.value < ethRequired) revert ("Insufficient collateral");

    loans[msg.sender] = Loan({
        alpBorrowed: alpAmount_,
        ethCollateral: msg.value,
        loanTimestamp: block.timestamp,
        active: true
    });
    token.mint(msg.sender, alpAmount_);
    emit LoanTaken(msg.sender, alpAmount_, msg.value);
}

//Repay loan and recover ETH collateral
function repayLoan() external notPaused {
    Loan storage loan= loans[msg.sender];
    if(!loan.active) revert ("No active loan");

    uint256 timeElapsed= block.timestamp - loan.loanTimestamp;
    uint256 interest= (loan.alpBorrowed * LOAN_INTEREST_RATE * timeElapsed) /(SECONDS_PER_YEAR * 100);
    uint256 totalToRepay= loan.alpBorrowed + interest;

    if (token.balanceOf(msg.sender)< totalToRepay) revert ("Insufficient ALP to repay laon");

    uint256 collateralToReturn= loan.ethCollateral;

    //CHECK- update state before external calls
    loan.active= false;
    loan.alpBorrowed=0;
    loan.ethCollateral=0;

    //EFECT-burn repaid tokens
    token.burn(msg.sender, totalToRepay);

    //INTERACTION- return collateral last
    (bool ok, )= msg.sender.call {value:collateralToReturn}("");
    if(!ok) revert ("Collateral return failed");

    emit LoanRepaid(msg.sender, totalToRepay, collateralToReturn);
}

//..........
//View functions
//Returns pending interest for a user
function pendingInterest(address user_) external view returns (uint256 interestInAlp) {
    uint256 deposited= accounts[user_].ethDeposited;
    if (deposited==0) return 0;
    uint256 timeElapsed= block.timestamp - accounts[user_].depositTimestamp;
    uint256 interestInEth= (deposited * INTEREST_RATE * timeElapsed) /(SECONDS_PER_YEAR * 100);
    interestInAlp= interestInEth * TOKENS_PER_ETH;
}

//Returns bank ETH balance
function bankBalance() external view returns (uint256) {
    return address(this).balance;
}

//Returns user account details
function getAccount(address user_) external view returns (
    uint256 ethDeposited,
    uint256 alpBalance,
    uint256 depositTimestamp,
    uint256 withdrawnToday
) {
    Account memory acc= accounts[user_];
    return (acc.ethDeposited, acc.alpBalance, acc.depositTimestamp, acc.withdrawnToday);
}

//Returns user loan details
function getLoan(address user_) external view returns (
    uint256 alpBorrowed,
    uint256 ethCollateral,
    bool active
) {
    Loan memory loan= loans[user_];
    return (loan.alpBorrowed, loan.ethCollateral, loan.active);
}
}