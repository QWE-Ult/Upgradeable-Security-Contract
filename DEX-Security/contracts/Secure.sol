// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Secure is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    error ZeroAddress();
    error AlreadyBlacklisted(address account);
    error NotWhitelisted(address account);
    error AddressBlacklisted(address account);
    error AmountZero();
    error ExceedsLimit(uint256 amount, uint256 limit);
    error EmergencyActive();
    error CooldownActive();
    error InsufficientBalance(uint256 available, uint256 required);
    error TransferFailed();
    error NoBalance();
    error NotInEmergency();
    error LimitZero();

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bool) internal whitelist;
    mapping(address => bool) internal blacklist;
    mapping(address => uint256) internal balances;
    mapping(address => uint256) internal lastBlockWithdrawn;

    bool public emergencyMode;
    uint256 public maxWithdrawalLimit;

    event Whitelisted(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event Blacklisted(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    event Deposit(address indexed account, uint256 amount);
    event SecureWithdraw(address indexed account, uint256 amount);
    event EmergencyWithdraw(address indexed account, uint256 amount);
    event EmergencyModeUpdated(bool status);
    event MaxWithdrawalLimitUpdated(uint256 newLimit);
    event BeforeDeposit(address indexed from, uint256 amount);
    event AfterDeposit(address indexed from, uint256 amount);
    event BeforeSecureWithdraw(address indexed to, uint256 amount);
    event AfterSecureWithdraw(address indexed to, uint256 amount);
    event BeforeEmergencyWithdraw(address indexed to, uint256 amount);
    event AfterEmergencyWithdraw(address indexed to, uint256 amount);

    function initialize(address owner, uint256 initialMaxWithdraw) public initializer {
        if (owner == address(0)) revert ZeroAddress();
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ADMIN_ROLE, owner);
        maxWithdrawalLimit = initialMaxWithdraw;
        emergencyMode = false;
    }

    modifier notBlacklisted() {
        if (blacklist[msg.sender]) revert AddressBlacklisted(msg.sender);
        _;
    }

    modifier onlyWhitelisted() {
        if (!whitelist[msg.sender]) revert NotWhitelisted(msg.sender);
        _;
    }

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}

    function _beforeDeposit(address from, uint256 amount) internal virtual {}
    function _afterDeposit(address from, uint256 amount) internal virtual {}
    function _beforeSecureWithdraw(address to, uint256 amount) internal virtual {}
    function _afterSecureWithdraw(address to, uint256 amount) internal virtual {}
    function _beforeEmergencyWithdraw(address to, uint256 amount) internal virtual {}
    function _afterEmergencyWithdraw(address to, uint256 amount) internal virtual {}

    function addToWhitelist(address account) external virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        if (account == address(0)) revert ZeroAddress();
        if (blacklist[account]) revert AlreadyBlacklisted(account);
        whitelist[account] = true;
        emit Whitelisted(account);
    }

    function removeFromWhitelist(address account) external virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        if (!whitelist[account]) revert NotWhitelisted(account);
        delete whitelist[account];
        emit RemovedFromWhitelist(account);
    }

    function addToBlacklist(address account) external virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        if (account == address(0)) revert ZeroAddress();
        if (whitelist[account]) {
            delete whitelist[account];
            emit RemovedFromWhitelist(account);
        }
        blacklist[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) external virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        if (!blacklist[account]) revert AddressBlacklisted(account);
        delete blacklist[account];
        emit RemovedFromBlacklist(account);
    }

    function setEmergencyMode(bool status) external virtual onlyRole(ADMIN_ROLE) {
        emergencyMode = status;
        emit EmergencyModeUpdated(status);
    }

    function setMaxWithdrawalLimit(uint256 newLimit) external virtual onlyRole(ADMIN_ROLE) {
        if (newLimit == 0) revert LimitZero();
        maxWithdrawalLimit = newLimit;
        emit MaxWithdrawalLimitUpdated(newLimit);
    }

    function pause() external virtual onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external virtual onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function deposit() external virtual payable whenNotPaused notBlacklisted {
        if (msg.value == 0) revert AmountZero();
        _beforeDeposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        _afterDeposit(msg.sender, msg.value);
    }

    function secureWithdraw(uint256 amount) external virtual nonReentrant whenNotPaused notBlacklisted onlyWhitelisted {
        if (amount == 0) revert AmountZero();
        if (amount > maxWithdrawalLimit) revert ExceedsLimit(amount, maxWithdrawalLimit);
        if (emergencyMode) revert EmergencyActive();
        if (lastBlockWithdrawn[msg.sender] >= block.number) revert CooldownActive();
        uint256 bal = balances[msg.sender];
        if (bal < amount) revert InsufficientBalance(bal, amount);
        _beforeSecureWithdraw(msg.sender, amount);
        balances[msg.sender] = bal - amount;
        lastBlockWithdrawn[msg.sender] = block.number;
        (bool ok, ) = payable(msg.sender).call{value: amount}(""); if (!ok) revert TransferFailed();
        emit SecureWithdraw(msg.sender, amount);
        _afterSecureWithdraw(msg.sender, amount);
    }

    function emergencyWithdraw() external virtual nonReentrant notBlacklisted {
        if (!emergencyMode) revert NotInEmergency();
        uint256 bal = balances[msg.sender];
        if (bal == 0) revert NoBalance();
        _beforeEmergencyWithdraw(msg.sender, bal);
        balances[msg.sender] = 0;
        (bool ok, ) = payable(msg.sender).call{value: bal}(""); if (!ok) revert TransferFailed();
        emit EmergencyWithdraw(msg.sender, bal);
        _afterEmergencyWithdraw(msg.sender, bal);
    }

    function isWhitelisted(address account) external view returns (bool) { return whitelist[account]; }
    function isBlacklisted(address account) external view returns (bool) { return blacklist[account]; }
    function balanceOf(address account) external view returns (uint256) { return balances[account]; }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable { balances[msg.sender] += msg.value; emit Deposit(msg.sender, msg.value); }
}
