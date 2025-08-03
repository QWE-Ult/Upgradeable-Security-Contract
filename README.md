# Upgradeable-Security-Contract
A reusable, upgradable base contract built on OpenZeppelin’s upgradeable libraries. It provides out-of-the-box role-based access control, pausing, reentrancy guards, whitelist/blacklist management, emergency withdrawal modes, and UUPS upgradeability hooks—so you can inherit and focus only on your custom business logic.

# upgradeable-security-contract

A reusable, upgradable base contract built on OpenZeppelin’s upgradeable libraries. It provides out-of-the-box role-based access control, pausing, reentrancy guards, whitelist/blacklist management, emergency withdrawal modes, and UUPS upgradeability hooks—so you can inherit and focus only on your custom business logic.

---

## Features

- **Role-Based Access Control**: Leverages OpenZeppelin’s `AccessControlUpgradeable` to manage `ADMIN_ROLE` and default admin.
- **Pausable**: Emergency pause/unpause via `PausableUpgradeable`.
- **Reentrancy Guard**: Protects sensitive functions using `ReentrancyGuardUpgradeable`.
- **Whitelist / Blacklist**: Manage allowed and blocked addresses.
- **Emergency Mode**: Toggle emergency withdrawal with full-balance access.
- **Withdrawal Limits**: Set and enforce a maximum per-withdraw limit.
- **UUPS Upgradeability**: Secure upgrade path using `UUPSUpgradeable`.
- **Lifecycle Hooks**: `_beforeDeposit`, `_afterDeposit`, `_beforeSecureWithdraw`, `_afterSecureWithdraw`, `_beforeEmergencyWithdraw`, `_afterEmergencyWithdraw` for custom logic overrides.

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-username>/upgradeable-security-contract.git
   cd upgradeable-security-contract
````

2. Install dependencies:

   ```bash
   npm install @openzeppelin/contracts-upgradeable
   ```

---

## Usage

Import and inherit the base contract in your own contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "upgradeable-security-contract/contracts/SecureUpgradeable.sol";

contract MyVault is SecureUpgradeable {
    function initialize(address owner, uint256 initialLimit) external initializer {
        __SecureUpgradeable_init(owner, initialLimit);
    }

    // Override hooks for custom logic
    function _beforeDeposit(address from, uint256 amount) internal override {
        // custom validation or events
    }
}
```

Ensure you call the initializer in your deployment script or constructor-equivalent for proxies.

---

## Configuration

* **ADMIN\_ROLE**: Addresses with this role can pause, blacklist, set limits, and authorize upgrades.
* **maxWithdrawalLimit**: Adjust via `setMaxWithdrawalLimit(uint256 newLimit)`.
* **emergencyMode**: Toggle via `setEmergencyMode(bool status)`.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

```
```
