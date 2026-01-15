// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./marketNode.sol";
import "./starNodeWork.sol";
import "./lock.sol";
event Stake(
    address indexed user,
    uint256 amount,
    uint256 position,
    uint256 time
);
interface ITRADE {
    function marketPrice() external view returns (uint);
}
event Take(address indexed user, uint256 amount);
event Claim(address indexed user, uint256 amount);
contract SSDSTAKED {
    enum opreate {
        stake,
        upStake,
        claim
    }
    struct StakedInfo {
        uint index;
        uint power;
        uint updateTime;
        uint available;
        uint accruedReward;
    }
    struct recordInfo {
        uint ssdAmount;
        uint stakeTime;
        uint endTime;
        uint postionAmount;
        uint updateTime;
        uint claimAmount;
    }
    StakedInfo public globalStakedInfo;
    mapping(address => StakedInfo) public userStakedInfos;

    mapping(address => recordInfo[]) public record;

    uint public startTime;
    uint public yearHalfCount;
    uint public yearHalfAmount = 24000000e18;
    uint public subHalfTime = 800 days;
    uint public days_30 = 30 days;
    uint public days_180 = 180 days;
    uint public days_360 = 360 days;
    MARKETNODE public marketNode;
    STARNODEWORK public starNodeWork;
    address public owner;
    IERC20 public ssd;
    address public lock;
    ITRADE public marketCap;
    constructor(address _ssd, address _marketCap, address _marketNode) {
        owner = msg.sender;
        marketNode = MARKETNODE(_marketNode);
        ssd = IERC20(_ssd);
        lock = address(new TokenLock(address(ssd)));
        ssd.approve(lock, type(uint).max);
        marketCap = ITRADE(_marketCap);
        starNodeWork = new STARNODEWORK(_ssd, _marketNode, address(this));
    }
    function setYearHalfAmount(uint amount) external {
        require(msg.sender == owner, "No owner and set the year half amount");
        yearHalfAmount = amount;
    }
    function setDays(
        uint _days_30,
        uint _days_180,
        uint _days_360
    ) external onlyOwner {
        days_30 = _days_30;
        days_180 = _days_180;
        days_360 = _days_360;
    }

    function setSubHalfTime(uint _time) external {
        require(msg.sender == owner, "No owner to set the time");
        subHalfTime = _time;
    }

    function getRecordInfos(
        address account
    ) external view returns (recordInfo[] memory) {
        return record[account];
    }

    function take(uint index) external {
        address sender = msg.sender;
        uint ssdValue;
        uint amount;
        recordInfo[] storage info = record[sender];
        require(
            block.timestamp >= info[index].endTime,
            "Not time to take token"
        );
        ssd.transfer(sender, info[index].ssdAmount);
        amount = info[index].postionAmount;

        uint time = info[index].endTime - info[index].stakeTime;
        if (time == 0) {
            ssdValue = (info[index].ssdAmount * 50) / 100;
        } else if (time == days_30) {
            ssdValue = info[index].ssdAmount;
        } else if (time == days_180) {
            ssdValue = (info[index].ssdAmount * 150) / 100;
        } else if (time == days_360) {
            ssdValue = info[index].ssdAmount * 2;
        }

        info[index] = info[info.length - 1];
        info.pop();
        if (amount > 0) {
            starNodeWork.updateHoldPosition(sender, -(int(amount)));
        }
        updateIndex(opreate.upStake, ssdValue);
        updateUserIndex(sender, opreate.upStake, ssdValue);
        emit Take(sender, amount);
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
    function claim() external {
        address sender = msg.sender;
        updateIndex(opreate.claim, 0);
        updateUserIndex(sender, opreate.claim, 0);

        StakedInfo storage userStakedInfo = userStakedInfos[sender];

        if (userStakedInfo.available > 0) {
            starNodeWork.ssdStakeClaimToStartLink(
                sender,
                userStakedInfo.available
            );

            uint temp = userStakedInfo.available;
            IERC20(ssd).transfer(sender, (temp * 30) / 100);
            TokenLock(lock).locking(sender, (temp * 70) / 100);
            userStakedInfo.accruedReward += temp;
            userStakedInfo.available = 0;
            emit Claim(sender, temp);
        }
    }
    function getPrincipalClaim(
        address _user,
        uint _index
    ) external view returns (uint) {
        recordInfo memory info = record[_user][_index];
        uint nowTime = block.timestamp > info.endTime
            ? info.endTime
            : block.timestamp;
        uint time = nowTime - info.updateTime;
        uint releaseAmount = (info.ssdAmount /
            (info.endTime - info.stakeTime)) * time;
        return releaseAmount;
    }
    function principalClaim(uint _index) external {
        address sender = msg.sender;
        recordInfo storage info = record[sender][_index];
        uint nowTime = block.timestamp > info.endTime
            ? info.endTime
            : block.timestamp;

        require(info.endTime != info.stakeTime, "Not time to claim");
        require(
            info.updateTime != info.endTime,
            "Not time to principal release"
        );
        if (info.updateTime < nowTime) {
            uint day;
            uint time = nowTime - info.updateTime;
            uint amount;
            uint releaseAmount = (info.ssdAmount /
                (info.endTime - info.stakeTime)) * time;
            ssd.transfer(sender, releaseAmount);
            info.claimAmount += releaseAmount;

            info.updateTime = nowTime;

            day = (info.endTime - info.stakeTime);
            if (day == days_30) {
                amount = releaseAmount;
            } else if (day == days_180) {
                amount = (releaseAmount * 150) / 100;
            } else if (day == days_360) {
                amount = releaseAmount * 2;
            } else {
                require(false, "Not time to principal claim with power");
            }
            updateIndex(opreate.upStake, amount);
            updateUserIndex(sender, opreate.upStake, amount);

            info.postionAmount -= amount;

            starNodeWork.updateHoldPosition(sender, -int(amount));

            if (info.updateTime == info.endTime) {
                recordInfo[] storage infos = record[sender];
                infos[_index] = infos[infos.length - 1];
                infos.pop();
            }
        }
    }

    function updateIndex(opreate _oprea, uint _power) internal {
        StakedInfo storage info = globalStakedInfo;
        if (info.updateTime == 0 || info.power == 0) {
            info.updateTime = block.timestamp;
            info.power += _power;
            halfYear();
            return;
        }
        uint release = halfYear();

        release = release * (block.timestamp - info.updateTime);

        release = release * 1e18;
        release = release / info.power;

        info.index += release;

        if (_oprea == opreate.stake) {
            info.power += _power;
        } else if (_oprea == opreate.upStake) {
            info.power -= _power;
        }

        info.updateTime = block.timestamp;
    }

    function awaitGetAmount(address user) external view returns (uint) {
        StakedInfo memory infoGlo = globalStakedInfo;
        StakedInfo memory infoUser = userStakedInfos[user];

        uint secRelease = getHalfYear();

        if (infoGlo.power == 0) return 0;

        uint _time = block.timestamp - infoGlo.updateTime;

        uint _amount = _time * secRelease;

        _amount = _amount * 1e18;

        _amount = _amount / infoGlo.power;

        uint _gloIndex = infoGlo.index + _amount;

        uint value = _gloIndex - infoUser.index;

        value = value * infoUser.power;
        value = value / 1e18;

        value = value + infoUser.available;

        return (value);
    }

    function updateUserIndex(
        address user,
        opreate _oprea,
        uint _power
    ) internal {
        StakedInfo storage info = userStakedInfos[user];

        info.updateTime = block.timestamp;

        uint value = info.power * (globalStakedInfo.index - info.index);

        value = value / 1e18;

        if (value != 0) {
            info.available += value;
        }

        if (_oprea == opreate.stake) {
            info.power += _power;
        } else if (_oprea == opreate.upStake) {
            info.power -= _power;
        }

        info.index = globalStakedInfo.index;
    }
    function stake(uint _amount, uint _days) external {
        address sender = msg.sender;

        uint amount;
        address sup = marketNode.supervisor(sender);
        require(sup != address(0), "Supervisor not found");

        if (_days >= days_30) {
            uint rate3 = marketCap.marketPrice();
            amount = (rate3 * _amount) / 1e18;
            if (amount > 0) {
                starNodeWork.updateHoldPosition(sender, int(amount));
            }
        }
        _stake(sender, _amount, _days);
        ssd.transferFrom(sender, address(this), _amount);
        uint nowTime = block.timestamp;
        record[sender].push(
            recordInfo({
                ssdAmount: _amount,
                postionAmount: amount,
                stakeTime: nowTime,
                endTime: nowTime + _days,
                updateTime: nowTime,
                claimAmount: 0
            })
        );
        emit Stake(sender, _amount, amount, _days);
    }

    function _stake(address _sender, uint _amount, uint _days) internal {
        require(
            _days == 0 ||
                _days == days_30 ||
                _days == days_180 ||
                _days == days_360,
            "Stakeing days error"
        );
        uint power;
        if (_days == 0) {
            power = (_amount * 50) / 100;
        } else if (_days == days_30) {
            power = _amount;
        } else if (_days == days_180) {
            power = (_amount * 150) / 100;
        } else if (_days == days_360) {
            power = _amount * 2;
        }

        updateIndex(opreate.stake, power);
        updateUserIndex(_sender, opreate.stake, power);
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is zero address");
        owner = _newOwner;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal {
        require(msg.sender == owner, "Not owner");
    }
}
