# 🏦 CryptoBank — Decentralized Crypto Bank

Decentralized bank built in Solidity 0.8.34, deployed on Ethereum Sepolia Testnet. Uses a custom ERC-20 token (ALP Token) for deposits, withdrawals, loans with collateral, interest rewards and emergency pause system.

---

## 📋 Description

CryptoBank is a two-contract system where users deposit ETH and receive ALP tokens in return. The bank manages all token lifecycle — minting on deposit and burning on withdrawal — while offering DeFi-style features like interest rewards and collateralized loans.

---

## 📁 Repository structure

```
cryptobank-solidity/
│
├── CryptoBank_token.sol      # ERC-20 ALP Token contract
├── CryptoBank.sol            # Main bank contract
└── README.md
```

---

## 🪙 ALP Token — `CryptoBank_token.sol`

Custom ERC-20 token created for this project.

| Property | Value |
|----------|-------|
| **Name** | ALP Token |
| **Symbol** | ALP |
| **Decimals** | 18 |
| **Initial Supply** | 0 — tokens are minted on deposit |
| **Mintable** | Yes — only by the bank |
| **Burnable** | Yes — only by the bank |

---

## 🏦 CryptoBank — `CryptoBank.sol`

Main contract handling all bank operations.

### Features

| Feature | Description |
|---------|-------------|
| **Deposit** | Send ETH → receive 1000 ALP per ETH |
| **Withdraw** | Return ALP → receive ETH back |
| **Interest** | 5% annual interest on deposits, claimable anytime |
| **Loans** | Borrow ALP by locking ETH as collateral (150% ratio) |
| **Loan repayment** | Repay ALP + 10% interest → recover collateral |
| **Daily limit** | Max 1 ETH withdrawal per day per user |
| **Roles** | Owner and admin system |
| **Emergency pause** | Owner or admin can pause all operations |

### Constants

```solidity
TOKENS_PER_ETH       = 1000      // 1 ETH = 1000 ALP
INTEREST_RATE        = 5%        // Annual deposit interest
LOAN_INTEREST_RATE   = 10%       // Annual loan interest
COLLATERAL_RATIO     = 150%      // Required collateral for loans
DAILY_WITHDRAWAL_LIMIT = 1 ether // Max daily withdrawal
```

---

## 🔗 Deployment on Sepolia

| Field | Value |
|-------|-------|
| **Network** | Ethereum Sepolia Testnet |
| **ALP Token** | `0xF3a2d316A3B16A112564E46419fe007EDFB7A068` |
| **CryptoBank** | `0x845929171Ef83d76043a29A534C0aff4C82C7816` |
| **Compiler** | Solidity 0.8.34 |

---

## 🚀 How to deploy

### Step 1 — Deploy the token
Deploy `CryptoBank_token.sol` first. Copy the contract address.

### Step 2 — Deploy the bank
Deploy `CryptoBank.sol` passing the token address in the constructor.

### Step 3 — Link the contracts
Call `setBank(bankAddress)` on the token contract passing the bank address. This gives the bank exclusive minting and burning rights.

---

## 🧪 How to test in Remix

**Deposit:**
1. Set Value to `1` ether
2. Call `deposit()`
3. Call `balanceOf(yourAddress)` on the token → should return `1000 * 10^18`

**Withdraw:**
1. Call `approve(bankAddress, amount)` on the token
2. Call `withdraw(alpAmount)` on the bank
3. Verify ETH returned to your wallet

**Take a loan:**
1. Set Value to `0.75` ether (150% collateral for 500 ALP loan)
2. Call `takeLoan(500 * 10^18)`
3. Verify ALP balance increased

**Repay loan:**
1. Call `approve(bankAddress, totalRepayAmount)` on the token
2. Call `repayLoan()`
3. Verify collateral returned

**Claim interest:**
1. Deposit ETH and wait some time
2. Call `claimInterest()`
3. Verify ALP balance increased

---

## 🛠️ Tools used

| Tool | Purpose |
|------|---------|
| Remix IDE 2.2.0 | Development and deployment |
| MetaMask | Transaction signing |
| Sepolia Etherscan | Contract verification |

---

## ⚠️ Disclaimer

This project was developed for educational purposes as part of a Blockchain Development Master's program. The contracts are deployed on Sepolia Testnet and handle no real value.

---

*Developed by **Ainhoa López Perelló** — Cybersecurity Specialist & Blockchain Developer*  
*[Hackchain](https://hackchain.io) — Web3 Security Certification Platform*
