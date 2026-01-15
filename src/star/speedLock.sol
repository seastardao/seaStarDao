pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./starNodeData.sol";
contract SPEEDLOCK {
    using SafeERC20 for IERC20;

    uint256 public UPGRADE_LOCK_DURATION;

    mapping(address => LockedToken) public upgradeLockedTokens;
    mapping(address => uint) public speedUpdateTime;
    mapping(address => uint) public speedNodeAmount;

    IERC20 public lockToken;
    address public oldLock;
    address public starNodeWork;
    mapping(address => uint) public speedCount;
    uint public targetTime = 30 days;

    uint[] public speedRate = [30, 50, 70, 100];
    STARNODEDATA public starNodeData;

    struct LockedToken {
        uint256 locked;
        uint256 lockTime;
        int256 unlocked;
    }

    event Locking(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _ssd, address _starNodeWork, address _starNodeData) {
        UPGRADE_LOCK_DURATION = 360 days;
        lockToken = IERC20(_ssd);
        starNodeWork = _starNodeWork;
        starNodeData = STARNODEDATA(_starNodeData);
    }

    function awaitSpeedRate(address _user) public view returns (uint) {
        uint temp = speedUpdateTime[_user];
        uint day = (block.timestamp - temp);
        uint speedAmount = speedNodeAmount[_user];
        uint rate;
        if (day >= targetTime && speedAmount > 0) {
            uint totalMarket = uint(starNodeData.totalMarket(_user));
            STARNODEDATA.MAXMARKET memory max = starNodeData.getMaxMarket(
                _user
            );
            uint value = totalMarket - uint(max.amount);
            if (value > speedAmount) {
                rate = ((value - speedAmount) * 1e10) / speedAmount;
                temp = speedCount[_user] > 3 ? 3 : speedCount[_user];
                temp = speedRate[temp] * 1e8;
                rate = rate > temp ? temp : rate;
            }
            return rate;
        }
        return 0;
    }
    function setSpeedUpdateTime(address _user) external onlyStarNodeWork {
        speedUpdateTime[_user] = block.timestamp;
    }

    function locking(address account, uint256 _lock) external {
        uint256 _now = block.timestamp;
        uint temp = speedUpdateTime[account];
        uint day = (_now - temp);
        uint speedAmount = speedNodeAmount[account];
        if (day >= targetTime && speedAmount == 0) {
            uint totalMarket = uint(starNodeData.totalMarket(account));
            STARNODEDATA.MAXMARKET memory max = starNodeData.getMaxMarket(
                account
            );
            uint value = totalMarket - uint(max.amount);
            speedNodeAmount[account] = value;
            speedUpdateTime[account] = _now;
        }

        lockToken.safeTransferFrom(msg.sender, address(this), _lock);
        LockedToken storage lt = upgradeLockedTokens[account];
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
        address _user = msg.sender;
        uint256 _now = block.timestamp;
        LockedToken storage lt = upgradeLockedTokens[_user];
        int256 unlocked = lt.unlocked;
        uint speedAmount = speedNodeAmount[_user];
        uint temp = speedUpdateTime[_user];
        uint day = (_now - temp);
        uint rate;
        uint amount;
        if (day >= targetTime && speedAmount == 0) {
            uint totalMarket = uint(starNodeData.totalMarket(_user));
            STARNODEDATA.MAXMARKET memory max = starNodeData.getMaxMarket(
                _user
            );
            uint value = totalMarket - uint(max.amount);
            speedNodeAmount[_user] = value;
            speedUpdateTime[_user] = block.timestamp;
        }
        if (day >= targetTime && speedAmount > 0) {
            uint totalMarket = uint(starNodeData.totalMarket(_user));
            STARNODEDATA.MAXMARKET memory max = starNodeData.getMaxMarket(
                _user
            );
            uint value = totalMarket - uint(max.amount);
            if (value > speedAmount) {
                rate = ((value - speedAmount) * 1e10) / speedAmount;
                temp = speedCount[_user] > 3 ? 3 : speedCount[_user];
                temp = speedRate[temp] * 1e8;
                rate = rate > temp ? temp : rate;
            }

            speedCount[_user]++;
            speedNodeAmount[_user] = value;
            speedUpdateTime[_user] = _now;
        }

        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            unlocked += int256(
                (lt.locked * (_now - lt.lockTime)) / UPGRADE_LOCK_DURATION
            );
        } else {
            unlocked += int256(lt.locked);
        }

        require(unlocked > 0, "no token available");
        lt.unlocked -= unlocked;
        if (rate > 0) {
            uint _unlocked = abs(lt.unlocked);
            lt.locked -= _unlocked;
            amount = (lt.locked * rate) / 1e10;
            lt.locked -= amount;
            lt.lockTime = _now;
            lt.unlocked = 0;
            lockToken.safeTransfer(_user, amount);
        }

        lockToken.safeTransfer(_user, uint256(unlocked));

        emit Withdraw(_user, uint256(unlocked));
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
    function abs(int x) internal pure returns (uint) {
        return x >= 0 ? uint(x) : uint(-x);
    }

    modifier onlyStarNodeWork() {
        require(msg.sender == starNodeWork, "only starNodeWork");
        _;
    }
}
