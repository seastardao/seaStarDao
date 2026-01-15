pragma solidity ^0.8.30;
contract STARNODEDATA {
    struct MAXMARKET {
        address user;
        int amount;
    }
    struct WeightInfo {
        uint index;
        uint rewardAmount;
    }

    mapping(address => int) public holdPositionAmount;
    mapping(address => mapping(address => int)) public directReferralAmount;
    mapping(address => int) public referralCount;
    mapping(address => bool) public referralCountStatus;
    mapping(address => uint) public starNodeSup;
    mapping(address => uint) public starNodeLight;
    mapping(address => int256) public directReferralTotalAmount;
    mapping(address => int) public totalMarket;
    mapping(address => MAXMARKET) public maxMarket;
    mapping(address => uint) public starLevel;

    address public starNodeWork;

    constructor(address _starNodeWork) {
        starNodeWork = _starNodeWork;
    }

    function setMaxMarket(
        address _user,
        MAXMARKET memory _market
    ) external onlyStarNodeWork {
        maxMarket[_user] = _market;
    }

    function updateMaxMarket(
        address _user,
        int _amount
    ) external onlyStarNodeWork {
        MAXMARKET storage _maxMarket = maxMarket[_user];
        _maxMarket.amount += _amount;
    }

    function setDirectReferralAmount(
        address _sup,
        address _user,
        int _positionAmount
    ) external onlyStarNodeWork {
        directReferralAmount[_sup][_user] = _positionAmount;
    }

    function setStarLevel(
        address _user,
        uint _level
    ) external onlyStarNodeWork {
        starLevel[_user] = _level;
    }

    function setTotalMarket(
        address _user,
        int _amount
    ) external onlyStarNodeWork {
        totalMarket[_user] += _amount;
    }

    function setDirectReferralTotalAmount(
        address _user,
        int256 _amount
    ) external onlyStarNodeWork {
        directReferralTotalAmount[_user] += _amount;
    }

    function setReferralCount(
        address _user,
        int _amount
    ) external onlyStarNodeWork {
        referralCount[_user] += _amount;
    }

    function setStarNodeSup(
        address _user,
        uint _amount
    ) external onlyStarNodeWork {
        starNodeSup[_user] += _amount;
    }
    function setStarNodeSupIsZero(address _user) external onlyStarNodeWork {
        starNodeSup[_user] = 0;
    }

    function setStarNodeLight(
        address _user,
        uint _amount
    ) external onlyStarNodeWork {
        starNodeLight[_user] += _amount;
    }
    function setStarNodeLightIsZero(address _user) external onlyStarNodeWork {
        starNodeLight[_user] = 0;
    }

    function setHoldPositionAmount(
        address _user,
        int _amount
    ) external onlyStarNodeWork {
        holdPositionAmount[_user] += _amount;
    }

    function getMaxMarket(
        address _user
    ) external view returns (MAXMARKET memory) {
        return maxMarket[_user];
    }

    modifier onlyStarNodeWork() {
        require(msg.sender == starNodeWork, "only starNodeWork");
        _;
    }
}
