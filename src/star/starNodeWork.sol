pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./speedLock.sol";
import "./lock.sol";
import "./marketNode.sol";
import "./starNodeData.sol";
import "./marketNode.sol";

contract STARNODEWORK {
    address public owner;
    address public ssdStakeContract;
    address public ssd;
    SPEEDLOCK public starLightLockToken;

    mapping(address => bool) public referralCountStatus;

    MARKETNODE public marketNode;
    STARNODEDATA public starNodeData;

    TokenLock public lockToken;
    constructor() {
        owner = msg.sender;
    }

    function ssdStakeClaimToStartLink(address _user, uint _amount) external {
        require(msg.sender == ssdStakeContract, "Not ssd stake contract");

        _updateSupervisorReward(_user, _amount);
        uint[20] memory rewardList = _rankDifference(_user, _amount);
        for (uint i; i < rewardList.length; i++) {
            uint256 user = rewardList[i] & ((1 << 160) - 1);
            uint256 amount = rewardList[i] >> 160;
            if (address(uint160(user)) == address(0)) {
                break;
            }
            starNodeData.setStarNodeLight(address(uint160(user)), amount);
        }
    }
    function claim(uint _type) external {
        address sender = msg.sender;
        uint amount;
        if (_type == 1) {
            amount = starNodeData.starNodeSup(sender);
            lockToken.locking(sender, (amount * 70) / 100);
            IERC20(ssd).transfer(sender, (amount * 30) / 100);
            starNodeData.setStarNodeSupIsZero(sender);
        } else if (_type == 2) {
            amount = starNodeData.starNodeLight(sender);
            starLightLockToken.locking(sender, (amount * 70) / 100);
            IERC20(ssd).transfer(sender, (amount * 30) / 100);
            starNodeData.setStarNodeLightIsZero(sender);
        }
    }

    function _rankDifference(
        address _user,
        uint _amount
    ) private view returns (uint[20] memory) {
        uint[] memory levelRewards = new uint[](10);
        levelRewards[0] = 20;
        levelRewards[1] = 30;
        levelRewards[2] = 40;
        levelRewards[3] = 50;
        levelRewards[4] = 60;
        levelRewards[5] = 70;
        levelRewards[6] = 75;
        levelRewards[7] = 80;
        levelRewards[8] = 85;
        levelRewards[9] = 90;
        uint256[20] memory rewardList;
        uint previousLevel;
        uint currentLevel;
        uint temp;
        uint s10Count;
        uint j;
        uint value;
        bool flag;
        address[] memory supervisors = MARKETNODE(marketNode).getSupervisor(
            _user
        );
        for (uint8 i; i < supervisors.length - 1; i++) {
            currentLevel = starNodeData.starLinkLevel(supervisors[i]);
            if (s10Count == 2) {
                break;
            }
            if (currentLevel == 0) {
                continue;
            }
            if (currentLevel == 10) {
                s10Count++;
            }
            if (currentLevel > previousLevel) {
                previousLevel = currentLevel;
                value = levelRewards[currentLevel - 1] - temp;
                value = (_amount * value) / 100;
                rewardList[j] = uint(uint160(supervisors[i])) | (value << 160);
                j++;
                temp = levelRewards[currentLevel - 1];
                flag = false;
            } else if (currentLevel == previousLevel && !flag) {
                flag = true;
                value = (_amount * 1) / 100;
                rewardList[j] = uint(uint160(supervisors[i])) | (value << 160);
                j++;
            }
        }
        return rewardList;
    }

    function _updateSupervisorReward(address _user, uint _amount) private {
        address[] memory supervisors = MARKETNODE(marketNode).getSupervisor(
            _user
        );
        uint[20] memory rewardRules = [
            (uint(100e18) << 64) | (1 << 8) | 5,
            (uint(100e18) << 64) | (2 << 8) | 5,
            (uint(100e18) << 64) | (3 << 8) | 5,
            (uint(100e18) << 64) | (4 << 8) | 5,
            (uint(100e18) << 64) | (5 << 8) | 3,
            (uint(100e18) << 64) | (6 << 8) | 3,
            (uint(200e18) << 64) | (7 << 8) | 3,
            (uint(200e18) << 64) | (8 << 8) | 3,
            (uint(200e18) << 64) | (9 << 8) | 2,
            (uint(200e18) << 64) | (10 << 8) | 2,
            (uint(200e18) << 64) | (11 << 8) | 2,
            (uint(200e18) << 64) | (12 << 8) | 2,
            (uint(300e18) << 64) | (13 << 8) | 2,
            (uint(300e18) << 64) | (14 << 8) | 2,
            (uint(300e18) << 64) | (15 << 8) | 1,
            (uint(300e18) << 64) | (16 << 8) | 1,
            (uint(500e18) << 64) | (17 << 8) | 1,
            (uint(500e18) << 64) | (18 << 8) | 1,
            (uint(500e18) << 64) | (19 << 8) | 1,
            (uint(500e18) << 64) | (20 << 8) | 1
        ];

        for (uint8 i = 1; i < supervisors.length && i <= 20; i++) {
            if (
                supervisors[i] == address(0) ||
                supervisors[i] == address(marketNode)
            ) {
                break;
            }

            uint rule = rewardRules[i - 1];

            if (
                uint(starNodeData.holdPositionAmount(supervisors[i])) >=
                (rule >> 64) &&
                uint(starNodeData.referralCount(supervisors[i])) >=
                ((rule >> 8) & ((1 << 56) - 1))
            ) {
                starNodeData.setStarNodeSup(
                    supervisors[i],
                    (_amount * (rule & ((1 << 8) - 1))) / 100
                );
            }
        }
    }

    function updateHoldPosition(address _user, int _amount) external {
        require(
            msg.sender == address(ssdStakeContract),
            "Not ssd stake contract"
        );
        require(_amount != 0, "Amount must be non-zero");
        uint speedTime = starLightLockToken.speedUpdateTime(_user);
        if (speedTime == 0) {
            starLightLockToken.setSpeedUpdateTime(_user);
        }

        address _sup = marketNode.supervisor(_user);
        starNodeData.setHoldPositionAmount(_user, _amount);
        int _positionAmount = starNodeData.holdPositionAmount(_user);
        starNodeData.setDirectReferralTotalAmount(_sup, _amount);

        bool shouldHaveReferral = _positionAmount >= 100e18;
        bool currentStatus = referralCountStatus[_user];
        if (shouldHaveReferral != currentStatus) {
            if (shouldHaveReferral) {
                starNodeData.setReferralCount(_sup, 1);
            } else {
                starNodeData.setReferralCount(_sup, -1);
            }
            referralCountStatus[_user] = shouldHaveReferral;
        }

        _updateSuperisorMaxmarketAndTotalMarket(_user, _amount);
        address tempUser;
        uint _level;
        address[] memory supervisors = marketNode.getSupervisor(_user);

        for (uint i; i < supervisors.length - 1; i++) {
            tempUser = supervisors[i];
            uint hold = uint(starNodeData.holdPositionAmount(tempUser)) / 1e18;
            uint dire = uint(starNodeData.referralCount(tempUser));
            uint total = uint(starNodeData.totalMarket(tempUser)) / 1e18;
            STARNODEDATA.MAXMARKET memory maxMarket = starNodeData.getMaxMarket(
                tempUser
            );
            uint maxMarketValue = uint(maxMarket.amount) / 1e18;
            total = total - maxMarketValue;
            _level = _computerLeave(hold, dire, total);
            starNodeData.setStarLinkLevel(tempUser, _level);
        }
    }
    function _computerLeave(
        uint _hold,
        uint _dire,
        uint _total
    ) private pure returns (uint leval) {
        uint[10] memory levalList = [
            (uint(100) << 128) | (5000 << 64) | 3,
            (uint(300) << 128) | (10000 << 64) | 3,
            (uint(500) << 128) | (50000 << 64) | 5,
            (uint(1000) << 128) | (100000 << 64) | 5,
            (uint(3000) << 128) | (200000 << 64) | 10,
            (uint(5000) << 128) | (500000 << 64) | 10,
            (uint(10000) << 128) | (1000000 << 64) | 15,
            (uint(10000) << 128) | (2000000 << 64) | 15,
            (uint(20000) << 128) | (4000000 << 64) | 20,
            (uint(20000) << 128) | (8000000 << 64) | 20
        ];
        uint rule;
        uint h;
        uint d;
        uint t;
        for (uint i; i < 10; i++) {
            rule = levalList[i];
            h = rule >> 128;
            t = (rule >> 64) & ((1 << 64) - 1);
            d = rule & ((1 << 64) - 1);
            if (_hold >= h && _dire >= d && _total >= t) {
                leval = i + 1;
            } else {
                return leval;
            }
        }
    }

    function _updateSuperisorMaxmarketAndTotalMarket(
        address _user,
        int _amount
    ) private returns (bool) {
        address temp;

        address[] memory supervisors = MARKETNODE(marketNode).getSupervisor(
            _user
        );
        uint256 currentTime = block.timestamp;
        address sup;
        temp = supervisors[0];
        for (uint8 i = 1; i < supervisors.length - 1; i++) {
            sup = supervisors[i];
            if (sup == address(0)) {
                break;
            }
            starNodeData.setTotalMarket(sup, _amount);

            int tempMarket = starNodeData.totalMarket(temp);
            int tempHold = starNodeData.holdPositionAmount(temp);
            int maxValue = tempMarket + tempHold;

            STARNODEDATA.MAXMARKET memory maxMarket = starNodeData.getMaxMarket(
                sup
            );
            if (maxMarket.user == temp) {
                starNodeData.updateMaxMarket(sup, _amount);
            }
            if (maxValue > maxMarket.amount) {
                maxMarket.user = temp;
                maxMarket.amount = maxValue;
                starNodeData.setMaxMarket(sup, maxMarket);
            }
            temp = sup;
        }

        return true;
    }
    function setAddress(
        address _ssd,
        address _ssdStaked,
        address _starNodeData,
        address _marketNode,
        address _starLightLockToken,
        address _lockToken
    ) external onlyOwner {
        marketNode = MARKETNODE(_marketNode);
        starNodeData = STARNODEDATA(_starNodeData);
        ssd = _ssd;
        starLightLockToken = SPEEDLOCK(_starLightLockToken);
        lockToken = TokenLock(_lockToken);

        IERC20(ssd).approve(address(lockToken), type(uint256).max);
        IERC20(ssd).approve(address(starLightLockToken), type(uint256).max);
        ssdStakeContract = _ssdStaked;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is zero address");
        owner = _newOwner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
