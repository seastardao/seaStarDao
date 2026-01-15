// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ILock.sol";
import "./interface/IPancakePair.sol";
import "./lock.sol";
event Stake(address indexed user, uint256 amount, uint256 time);
event Take(address indexed user, uint256 amount);
event Claim(address indexed user, uint256 amount);
interface ISSD {
    function uniswapV2Pair() external view returns (address);
}
contract SSDLPPOOL {
    enum opreate {
        stake,
        upStake,
        claim
    }
    struct StakedInfo {
        uint index;
        uint stakedAmount;
        uint updateTime;
        uint available;
        uint accruedReward;
    }
    struct recordInfo {
        uint lpAmount;
        uint stakeTime;
        uint endTime;
    }

    StakedInfo public globalStakedInfo;
    mapping(address => StakedInfo) public userStakedInfos;

    mapping(address => recordInfo[]) public record;

    uint public startTime;
    uint public yearHalfCount;
    uint public yearHalfAmount = 18000000e18;
    uint public subHalfTime = 800 days;
    uint public days_100 = 100 days;
    uint public days_200 = 200 days;
    uint public days_300 = 300 days;
    uint public days_500 = 500 days;
    address public owner;
    address public consensusAddress;
    IERC20 public ssd;
    address public lock;
    IPancakePair public ssdPair;

    constructor(address _ssd) {
        owner = msg.sender;
        lock = address(new TokenLock(_ssd));
        ssd = IERC20(_ssd);
        ssdPair = IPancakePair(ISSD(_ssd).uniswapV2Pair());
        IERC20(ssd).approve(address(lock), type(uint).max);
    }

    function setDays(
        uint _days100,
        uint _days200,
        uint _days300,
        uint _days500
    ) external {
        require(msg.sender == owner, "No owner to set the days");
        days_100 = _days100;
        days_200 = _days200;
        days_300 = _days300;
        days_500 = _days500;
    }
    function setConsensus(address _consensusAddress) external {
        require(msg.sender == owner, "No owner to set the consensus address");
        consensusAddress = _consensusAddress;
    }

    function setSubHalfTime(uint _time) external {
        require(msg.sender == owner, "No owner to set the time");
        subHalfTime = _time;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "Not owner");
        owner = _owner;
    }

    function getRecordInfos(
        address account
    ) external view returns (recordInfo[] memory) {
        return record[account];
    }

    function takeLp(uint index) external {
        address sender = msg.sender;
        uint cTime = block.timestamp;
        uint lpValue;

        recordInfo[] storage info = record[sender];
        uint amount = info[index].lpAmount;
        require(info.length > index, "Take lp error for index too long");
        require(
            info[index].endTime <= cTime,
            "Take lp error for exceed the time"
        );
        uint time = info[index].endTime - info[index].stakeTime;
        if (time == days_100) {
            lpValue = amount;
        }
        if (time == days_200) {
            lpValue = (amount * 150) / 100;
        }
        if (time == days_300) {
            lpValue = amount * 2;
        }
        if (time == days_500) {
            lpValue = amount * 2;
        }
        ssdPair.transfer(sender, info[index].lpAmount);

        info[index] = info[info.length - 1];
        info.pop();

        updateIndex(opreate.upStake, lpValue);
        updateUserIndex(sender, opreate.upStake, lpValue);
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

    function claim() public {
        address sender = msg.sender;
        updateIndex(opreate.claim, 0);
        updateUserIndex(sender, opreate.claim, 0);

        StakedInfo storage userStakedInfo = userStakedInfos[sender];

        if (userStakedInfo.available > 0) {
            uint temp = userStakedInfo.available;
            IERC20(ssd).transfer(sender, (temp * 30) / 100);
            TokenLock(lock).locking(sender, (temp * 70) / 100);
            userStakedInfo.accruedReward += temp;
            userStakedInfo.available = 0;
            emit Claim(sender, temp);
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
        if (_oprea == opreate.upStake) {
            info.stakedAmount -= lpAmount;
        }

        info.updateTime = block.timestamp;
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

        return (value);
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

        if (value != 0) {
            info.available += value;
        }

        if (_oprea == opreate.stake) {
            info.stakedAmount += lpAmount;
        }
        if (_oprea == opreate.upStake) {
            info.stakedAmount -= lpAmount;
        }

        info.index = globalStakedInfo.index;
    }

    function stake(uint _amount, uint _days) external {
        _stake(msg.sender, _amount, _days);
        ssdPair.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount, _days);
    }

    function _stake(address _sender, uint _amount, uint _days) internal {
        require(
            _days == days_100 || _days == days_200 || _days == days_300,
            "Stakeing days error"
        );
        uint lpAmount;
        if (_days == days_100) {
            lpAmount = _amount;
        }
        if (_days == days_200) {
            lpAmount = (_amount * 150) / 100;
        }
        if (_days == days_300) {
            lpAmount = _amount * 2;
        }

        updateIndex(opreate.stake, lpAmount);
        updateUserIndex(_sender, opreate.stake, lpAmount);

        record[_sender].push(
            recordInfo({
                lpAmount: _amount,
                stakeTime: block.timestamp,
                endTime: block.timestamp + _days
            })
        );
    }
    function consensusToStake(address _sender, uint _amount) external {
        require(msg.sender == consensusAddress, "Only consensus can call");
        ssdPair.transferFrom(msg.sender, address(this), _amount);
        updateIndex(opreate.stake, _amount * 2);
        updateUserIndex(_sender, opreate.stake, _amount * 2);

        record[_sender].push(
            recordInfo({
                lpAmount: _amount,
                stakeTime: block.timestamp,
                endTime: block.timestamp + days_500
            })
        );
        emit Stake(_sender, _amount, days_500);
    }
}
