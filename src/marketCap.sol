pragma solidity ^0.8.30;
import {IROUTE} from "./interface/IROUTE.sol";
import {ITOKEN} from "./interface/IToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract TREASURY {
    address public owner = address(0xDead);
    constructor(address _marketCap, address _mos, address _ssd) {
        ITOKEN(_mos).approve(_marketCap, type(uint256).max);
        ITOKEN(_ssd).approve(_marketCap, type(uint256).max);
    }
}

contract MARKETCAP {
    using Math for uint256;
    address public owner;
    address public ssd;
    address constant mos = 0xc9C8050639c4cC0DF159E0e47020d6e392191407;
    address constant mosPair = 0xB51f9508B88F0868aE14E74C5D7d1F34E2f419c1;
    address public ssdPair;
    address public deadAddress = address(0xDead);
    uint public marketPrice;
    uint public tradeTime;
    uint public buySsdTotalAmount;
    uint public sellSsdTotalAmount;
    uint public sellSsdToCount;
    uint public buySsdToCount;
    uint public addSSDLPTotalAmount;

    uint public periodTime = 3 days;
    address public treasury;
    bool private _locked;
    mapping(address => bool) private tradeAddress;
    IROUTE constant route = IROUTE(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor(address _ssd) {
        owner = msg.sender;
        ssd = _ssd;
        ITOKEN(ssd).approve(address(route), type(uint).max);
        treasury = address(new TREASURY(address(this), mos, ssd));
        ITOKEN(mos).approve(address(route), type(uint).max);
        ssdPair = ITOKEN(ssd).uniswapV2Pair();
    }
    function isTrade() external view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = ssd;
        path[1] = mos;

        uint _now = block.timestamp;
        uint priceM = getPrice(mos);
        uint priceS = getPrice(ssd);
        uint currentPrice = (priceS * priceM) / 1e18;

        if (tradeTime == 0) {
            return false;
        }
        if (_now - tradeTime >= periodTime) {
            return true;
        }

        uint price = marketPrice + (marketPrice * 5) / 100;
        if (currentPrice >= price) {
            return true;
        }
        price = marketPrice - (marketPrice * 5) / 100;
        if (currentPrice <= price) {
            return true;
        }

        return false;
    }
    function trade() external nonReentrant returns (bool) {
        require(tradeAddress[msg.sender], "only address");

        uint _now = block.timestamp;
        uint priceM = getPrice(mos);
        uint priceS = getPrice(ssd);
        uint currentPrice = (priceS * priceM) / 1e18;

        uint temp;
        if (tradeTime == 0) {
            tradeTime = _now;
            marketPrice = currentPrice;
            return true;
        } else if (_now - tradeTime >= periodTime) {
            tradeTime = _now;
            marketPrice = currentPrice;
            return true;
        }

        uint price = marketPrice + (marketPrice * 5) / 100;

        if (currentPrice >= price) {
            uint targetPrice = marketPrice + (marketPrice * 3) / 100;

            uint mintAmount = computerSsd(targetPrice);
            if (mintAmount == 0) {
                return false;
            }
            uint toSSDLp = (mintAmount * 125) / 1000;
            address[] memory path = new address[](2);
            path[0] = ssd;
            path[1] = mos;
            swap(path, toSSDLp);
            uint amount = ITOKEN(mos).balanceOf(address(this));
            uint liquidity = liquify(ssd, mos, toSSDLp, amount);

            addSSDLPTotalAmount += liquidity;
            sellSsdTotalAmount += mintAmount;
            sellSsdToCount++;

            temp = mintAmount - toSSDLp - toSSDLp;
            swap(path, temp);

            temp = ITOKEN(mos).balanceOf(address(this));
            ITOKEN(mos).transfer(treasury, temp);
            return true;
        }
        price = marketPrice - (marketPrice * 5) / 100;
        if (currentPrice <= price) {
            uint targetPrice = (marketPrice * 97) / 100;
            uint amount = computerSsd(targetPrice);

            return true;
        }
        return false;
    }
    function getPrice(address token) private view returns (uint) {
        require(token == mos || token == ssd, "Invalid token");
        if (token == mos) {
            address token0 = ITOKEN(mosPair).token0();
            (uint112 reserve0, uint112 reserve1, ) = ITOKEN(mosPair)
                .getReserves();

            if (token0 == mos) {
                return (uint(reserve1) * 1e18) / uint(reserve0);
            } else {
                return (uint(reserve0) * 1e18) / uint(reserve1);
            }
        } else if (token == ssd) {
            address token0 = ITOKEN(ssdPair).token0();
            (uint112 reserve0, uint112 reserve1, ) = ITOKEN(ssdPair)
                .getReserves();
            if (token0 == ssd) {
                return (uint(reserve1) * 1e18) / uint(reserve0);
            } else {
                return (uint(reserve0) * 1e18) / uint(reserve1);
            }
        }
    }

    function computerSsd(uint _targetPrice) private returns (uint) {
        uint res0;
        uint res1;

        uint targetPrice = _targetPrice;
        uint Pm = getPrice(mos);

        (res0, res1, ) = ITOKEN(ssdPair).getReserves();
        address token0 = ITOKEN(ssdPair).token0();
        if (token0 == ssd) {
            uint temp = res0;
            res0 = res1;
            res1 = temp;
        }

        uint value = ((res0 * res1 * 1000000) / ((_targetPrice * 1000000) / Pm))
            .sqrt();

        if (value >= res1) {
            value = value - res1;

            uint temp = value;

            value = (temp * 106666666666667) / 1e14;
            uint halfValue = value / 2;
            uint balance = ITOKEN(ssd).balanceOf(treasury);
            if (balance >= halfValue) {
                address[] memory path = new address[](2);
                path[0] = ssd;
                path[1] = mos;
                ITOKEN(ssd).transferFrom(treasury, address(this), halfValue);
                swap(path, halfValue);
                return value / 2;
            }
            value = (temp * 11428571428571) / 1e13;
            return value;
        } else {
            address[] memory path = new address[](2);
            path[0] = mos;
            path[1] = ssd;
            value = (res0 * res1) / value;
            value = value - res0;

            uint balance = ITOKEN(mos).balanceOf(treasury);
            if (balance <= 0) {
                return 0;
            }

            balance = balance >= value ? value : balance;
            ITOKEN(mos).transferFrom(treasury, address(this), balance);
            uint temp = ITOKEN(ssd).balanceOf(address(this));
            buySsdTotalAmount += balance;
            buySsdToCount++;
            swap(path, balance);
            uint temp1 = ITOKEN(ssd).balanceOf(address(this));
            temp = temp1 - temp;
            ITOKEN(ssd).transfer(treasury, temp);
            return 0;
        }
    }
    function swap(address[] memory path, uint tokenAmount) private {
        route.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 10
        );
    }
    function liquify(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) private returns (uint liquidity) {
        (, , uint liquidity) = route.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0,
            0,
            deadAddress,
            block.timestamp
        );
        return liquidity;
    }
    function setTime(uint _time) external onlyOwner {
        periodTime = _time;
    }

    function setTradeAddress(address _addr) public {
        require(msg.sender == owner, "only owner");
        tradeAddress[_addr] = true;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}
