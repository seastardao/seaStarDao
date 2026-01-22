// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMosLpPool} from "./interface/IMosLpPool.sol";
import {TokenLock} from "./lock.sol";

contract MOSLPSSDPOOL {
    enum opreate {
        stake,
        unStake,
        claim
    }

    struct StakedInfo {
        uint index;
        uint stakedAmount;
        uint updateTime;
        uint available;
        uint accruedReward;
    }

    StakedInfo public globalStakedInfo;
    mapping(address => StakedInfo) public userStakedInfos;
    uint public startTime;
    uint public yearHalfCount;
    uint public yearHalfAmount = 3000000e18;
    uint public subHalfTime = 800 days;

    address public owner;
    IERC20 public ssd;
    address public lock;
    IMosLpPool public mosLpPool;

    constructor(address _mosLpPool, address _ssd) {
        owner = msg.sender;
        ssd = IERC20(_ssd);
        lock = address(new TokenLock(_ssd));
        mosLpPool = IMosLpPool(_mosLpPool);
        IERC20(ssd).approve(address(lock), type(uint).max);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "Not owner");
        owner = _owner;
    }

    function setSubHalfTime(uint _time) external {
        require(msg.sender == owner, "No owner to set the time");
        subHalfTime = _time;
    }

    function sync() public {
        address sender = msg.sender;
        _sync(sender);
    }
    function _sync(address sender) internal {
        uint newAmount = IMosLpPool(mosLpPool).balanceOf(sender);
        uint temp;
        StakedInfo memory userInfo = userStakedInfos[sender];

        if (newAmount == userInfo.stakedAmount) return;

        if (newAmount > userInfo.stakedAmount) {
            temp = newAmount - userInfo.stakedAmount;
            updateIndex(opreate.stake, temp);
            updateUserIndex(sender, opreate.stake, temp);
        }
        if (newAmount < userInfo.stakedAmount) {
            temp = userInfo.stakedAmount - newAmount;
            updateIndex(opreate.unStake, temp);
            updateUserIndex(sender, opreate.unStake, temp);
        }
    }

    function halfYear() internal returns (uint) {
        require(subHalfTime > 0, "SubHalf time error");
        startTime = startTime == 0 ? block.timestamp : startTime;
        uint yearCount = (block.timestamp - startTime) / subHalfTime;
        uint value;
        if (yearHalfCount <= yearCount) {
            yearHalfCount = yearCount + 1;
            yearHalfAmount = yearHalfAmount / 2;
        }
        value = yearHalfAmount;
        return value / subHalfTime;
    }

    function getHalfYear() internal view returns (uint) {
        if (yearHalfAmount == 0) {
            return 0;
        }
        uint value = yearHalfAmount;
        return value / subHalfTime;
    }

    function claim() public {
        address sender = msg.sender;
        _sync(sender);
        updateIndex(opreate.claim, 0);
        updateUserIndex(sender, opreate.claim, 0);
        StakedInfo storage userStakedInfo = userStakedInfos[sender];

        if (userStakedInfo.available > 0) {
            uint temp = userStakedInfo.available;
            IERC20(ssd).transfer(sender, (temp * 30) / 100);
            TokenLock(lock).locking(sender, (temp * 70) / 100);
            userStakedInfo.accruedReward += temp;
            userStakedInfo.available = 0;
        }
    }

    function updateIndex(opreate _oprea, uint lpAmount) internal {
        StakedInfo storage info = globalStakedInfo;
        if (info.updateTime == 0 || info.stakedAmount == 0) {
            info.updateTime = block.timestamp;
            info.stakedAmount += lpAmount;
            halfYear();
            return;
        }
        uint release = halfYear();

        release = release * (block.timestamp - info.updateTime);

        release = release * 1e18;

        release = release / info.stakedAmount;

        info.index += release;

        if (_oprea == opreate.stake) {
            info.stakedAmount += lpAmount;
        }
        if (_oprea == opreate.unStake) {
            info.stakedAmount -= lpAmount;
        }
        if (release > 0) {
            info.updateTime = block.timestamp;
        }
    }

    function awaitGetAmount(address user) external view returns (uint) {
        StakedInfo memory infoGlo = globalStakedInfo;
        StakedInfo memory infoUser = userStakedInfos[user];

        uint secRelease = getHalfYear();

        if (infoGlo.stakedAmount == 0) return 0;

        uint _time = block.timestamp - infoGlo.updateTime;

        uint _amount = _time * secRelease;

        _amount = _amount * 1e18;

        _amount = _amount / infoGlo.stakedAmount;

        uint _gloIndex = infoGlo.index + _amount;

        uint value = _gloIndex - infoUser.index;

        value = value * infoUser.stakedAmount;
        value = value / 1e18;
        value = value + infoUser.available;

        return value;
    }

    function updateUserIndex(
        address user,
        opreate _oprea,
        uint lpAmount
    ) internal {
        StakedInfo storage info = userStakedInfos[user];

        info.updateTime = block.timestamp;
        uint value = info.stakedAmount * (globalStakedInfo.index - info.index);

        value = value / 1e18;

        if (value > 0) {
            info.available += value;
        }

        if (_oprea == opreate.stake) {
            info.stakedAmount += lpAmount;
        }
        if (_oprea == opreate.unStake) {
            info.stakedAmount -= lpAmount;
        }

        info.index = globalStakedInfo.index;
    }
}
