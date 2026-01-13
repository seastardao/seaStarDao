pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IROUTE.sol";
import "./interface/ILPQUA.sol";
import "./interface/IPAIR.sol";
import "./interface/INFT.sol";
import "./interface/ISSDLPPOOL.sol";
import "./consensusNft.sol";
import "./lock.sol";
interface SPARKPOOL {
    function balanceOf(address) external view returns (uint256);
}
contract CONSENSUS {
    uint public consensusTotal;
    address public owner;
    address public ssdLpPool;
    IERC20 public mos;
    IERC20 public ssd;
    IROUTE public route;
    ILPQUA public lpqua;
    address public ssdPair;
    address public sparkPool;
    TokenLock public lock;
    uint public tempLpqua;
    address public nft;
    bool private _locked;

    mapping(address => bool) public isConsensus;

    constructor() {
        owner = msg.sender;
    }
    function setAddress(
        address _lpqua,
        address _mos,
        address _ssdPair,
        address _route,
        address _ssd,
        address _sparkPool,
        address _ssdLpPool,
        address _consensusNft
    ) external {
        require(msg.sender == owner, "Not owner");
        lpqua = ILPQUA(_lpqua);
        mos = IERC20(_mos);
        ssdPair = _ssdPair;
        route = IROUTE(_route);
        ssd = IERC20(_ssd);
        sparkPool = _sparkPool;
        ssdLpPool = _ssdLpPool;
        nft = _consensusNft;
        lock = new TokenLock(address(ssd));
        IERC20(ssd).approve(address(lock), type(uint).max);
        IERC20(mos).approve(address(route), type(uint).max);
        IERC20(ssd).approve(address(route), type(uint).max);
        IERC20(ssdPair).approve(_ssdLpPool, type(uint).max);
        ssdLpPool = _ssdLpPool;
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = _newOwner;
    }
    function joinConsensus() external nonReentrant returns (bool) {
        address sender = msg.sender;
        require(!isConsensus[sender], "Already consensus");
        uint count = lpqua.nft(sender);
        if (count > 0 && count <= 5) {
            uint mosAmount = count * 100e18;
            bool success = IERC20(mos).transferFrom(
                sender,
                address(this),
                mosAmount
            );
            require(success, "Transfer failed");

            (, , uint liquidity) = route.addLiquidity(
                address(mos),
                address(ssd),
                mosAmount,
                mosAmount * 5,
                1,
                1,
                address(this),
                block.timestamp + 1000
            );
            ISSDLPPOOL(ssdLpPool).consensusToStake(sender, liquidity);
            for (uint i = 0; i < count; i++) {
                CONSENSUSNFT(nft).mintNft(sender);
            }
            consensusTotal += count;
            isConsensus[sender] = true;

            uint amount = SPARKPOOL(sparkPool).balanceOf(sender);
            if (amount > 0) {
                IERC20(ssd).transfer(sender, (amount * 30) / 100);
                lock.locking(sender, (amount * 70) / 100);
            }
            return true;
        }
        return false;
    }
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
}
