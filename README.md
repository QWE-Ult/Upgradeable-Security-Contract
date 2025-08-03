# Upgradeable-Security-Contract
A reusable, upgradable base contract built on OpenZeppelin’s upgradeable libraries. It provides out-of-the-box role-based access control, pausing, reentrancy guards, whitelist/blacklist management, emergency withdrawal modes, and UUPS upgradeability hooks—so you can inherit and focus only on your custom business logic.

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

## Technologies Used

- **Solidity** ^0.8.0
- **OpenZeppelin Contracts Upgradeable**
- **UUPS (Universal Upgradeable Proxy Standard)**
- **Hardhat / Foundry (recommended for testing and deployment)**
- **npm / Node.js** for dependency management

---

## Usage

Import and inherit the base contract in your own contract:

solidity
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


Ensure you call the initializer in your deployment script or constructor-equivalent for proxies.

---

## Configuration

* **ADMIN\_ROLE**: Addresses with this role can pause, blacklist, set limits, and authorize upgrades.
* **maxWithdrawalLimit**: Adjust via setMaxWithdrawalLimit(uint256 newLimit).
* **emergencyMode**: Toggle via setEmergencyMode(bool status).
* **Whitelist**: Manage via addToWhitelist(address) and removeFromWhitelist(address).
* **Blacklist**: Manage via addToBlacklist(address) and removeFromBlacklist(address).
* **Pause / Unpause**: Use pause() and unpause() to control contract state.



---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

```
```
## Acknowledgements

This code would not have been possible without the invaluable support, guidance, and encouragement of my senior team members.

I would like to sincerely thank **Laksh Sharma**, **Hardik Rajput** for their constant mentorship throughout the development process. Their experience, feedback, and collaborative spirit helped me better understand upgradable contract patterns, security best practices, and smart contract architecture.

They guided me in refining key concepts, improving the contract's structure, and ensuring that the implementation adhered to both practical use cases and best coding standards. Their involvement greatly contributed to making this contract more robust, modular, and production-ready.


