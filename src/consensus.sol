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
interface ISSD {
    function uniswapV2Pair() external view returns (address);
}
contract CONSENSUS {
    uint public consensusTotal;
    address public owner;
    address public ssdLpPool;
    IERC20 public mos = IERC20(0xc9C8050639c4cC0DF159E0e47020d6e392191407);
    IERC20 public ssd;
    IROUTE public route = IROUTE(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ILPQUA public lpqua = ILPQUA(0x084285aa344A31d72D1505B1e79C698479134F79);
    address public ssdPair;
    address public sparkPool = 0x7dc416F1417b007A8aa73D79D5eFEC0cefB1Ab1C;
    TokenLock public lock;
    uint public tempLpqua;
    address public nft;
    bool private _locked;

    mapping(address => bool) public isConsensus;

    constructor(address _ssd, address _ssdLpPool) {
        owner = msg.sender;
        ssdPair = ISSD(_ssd).uniswapV2Pair();
        ssd = IERC20(_ssd);
        nft = address(new CONSENSUSNFT(address(this)));
        lock = new TokenLock(address(ssd));
        ssdLpPool = _ssdLpPool;
        IERC20(ssd).approve(address(lock), type(uint).max);
        IERC20(mos).approve(address(route), type(uint).max);
        IERC20(ssd).approve(address(route), type(uint).max);
        IERC20(ssdPair).approve(ssdLpPool, type(uint).max);
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
