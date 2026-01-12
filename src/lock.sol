// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenLock {
    using SafeERC20 for IERC20;

    uint256 public UPGRADE_LOCK_DURATION;

    mapping(address => LockedToken) public upgradeLockedTokens;

    IERC20 public lockToken;
    address public oldLock;
    address public owner;

    struct LockedToken {
        uint256 locked;
        uint256 lockTime;
        int256 unlocked;
    }

    event Locking(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _lockToken) {
        lockToken = IERC20(_lockToken);
        UPGRADE_LOCK_DURATION = 360 days;
        owner = msg.sender;
    }
    function locking(address account, uint256 _lock) external {
        lockToken.safeTransferFrom(msg.sender, address(this), _lock);
        LockedToken storage lt = upgradeLockedTokens[account];
        uint256 _now = block.timestamp;
        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            uint256 amount = (lt.locked * (_now - lt.lockTime)) /
                UPGRADE_LOCK_DURATION;
            lt.locked = lt.locked - amount + _lock;
            lt.unlocked += int256(amount);
        } else {
            lt.unlocked += int256(lt.locked);
            lt.locked = _lock;
        }
        lt.lockTime = _now;

        emit Locking(account, _lock);
    }

    function withdraw() external {
        LockedToken storage lt = upgradeLockedTokens[msg.sender];
        int256 unlocked = lt.unlocked;
        uint256 _now = block.timestamp;

        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            unlocked += int256(
                (lt.locked * (_now - lt.lockTime)) / UPGRADE_LOCK_DURATION
            );
        } else {
            unlocked += int256(lt.locked);
        }

        require(unlocked > 0, "no token available");

        lt.unlocked -= unlocked;

        lockToken.safeTransfer(msg.sender, uint256(unlocked));

        emit Withdraw(msg.sender, uint256(unlocked));
    }

    function available(address _account) public view returns (uint256) {
        LockedToken memory lt = upgradeLockedTokens[_account];
        int256 unlocked = lt.unlocked;
        uint256 _now = block.timestamp;

        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            unlocked += int256(
                (lt.locked * (_now - lt.lockTime)) / UPGRADE_LOCK_DURATION
            );
        } else {
            unlocked += int256(lt.locked);
        }
        return uint256(unlocked);
    }
}
