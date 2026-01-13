pragma solidity ^0.8.30;

interface ISTARNODEDATA {
    struct INDEX {
        uint globalIndex; //全局索引
        uint userIndex; //用户索引
        uint totalAmount; //记录总分配的奖励
    }
    struct MAXMARKET {
        address user;
        int amount;
    }
    // 为公共映射index声明getter函数
    function index(address _user) external view returns (INDEX memory);
    function maxMarket(address _user) external view returns (MAXMARKET memory);

    // 为其他映射声明getter函数
    function getSubordinateRewardList(
        address _user
    ) external view returns (uint[10] memory);
    function getS9(address _user) external view returns (address[] memory);
    function getS8(address _user) external view returns (address[] memory);
    function subordinateRewardList(
        address _user
    ) external view returns (uint[10] memory);
    function holdPositionAmount(address _user) external view returns (int);
    function referralCount(address _user) external view returns (uint);
    function directReferralTotalAmount(
        address _user
    ) external view returns (uint);
    function totalMarket(address _user) external view returns (int);
    function speedUpdateTime(address _user) external view returns (uint);
    function speedNodeAmount(address _user) external view returns (uint);
    function starLinkLevel(address _user) external view returns (uint);
    function starLightAccumulate(address _user) external view returns (uint);
    function starNodeSup(address _user) external view returns (uint);
    function starNodeSub(address _user) external view returns (uint);
    function starNodeLight(address _user) external view returns (uint);
    function getS10(address _user) external view returns (address[] memory);
    function pushS9(address _user, address _S8USER) external;
    function pushS10(address _user, address _S9USER) external;
    // setter函数
    function setSubordinateRewardList(
        address _user,
        uint[10] memory _list
    ) external;
    function setMaxMarket(address _owner, MAXMARKET memory _market) external;
    function setIndex(address _user, INDEX memory _index) external;
    function setBalanceOf(address _user, uint _amount) external;
    function setDirectReferralTotalAmount(address _user, int _amount) external;
    function setReferralCount(address _user, int _amount) external;
    function setTotalMarket(address _user, int _amount) external;
    function setSpeedUpdateTime(address _user, uint _time) external;
    function setSpeedNodeAmount(address _user, uint _amount) external;
    function setStarLinkLevel(address _user, uint _level) external;
    function setStarLightAccumulate(address _user, uint _amount) external;
    function setStarNodeSup(address _user, uint _amount) external;
    function setStarNodeSubro(address _user, uint _amount) external;
    function setStarNodeLight(address _user, uint _amount) external;
    function setS9(address _user, address[] memory _S8USER) external;
    function setS10(address _user, address[] memory _S9USER) external;
    function setDirectReferralAmount(
        address _sup,
        address _user,
        int _positionAmount
    ) external;

    // 其他必要的函数声明
    function setHoldPositionAmount(address _user, int _amount) external;
    function setStarNodeWork(address _starNodeWork) external;
    function starNodeWork() external view returns (address);
}
