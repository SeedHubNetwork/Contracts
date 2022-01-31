//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Configuration.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LP_ICO is Ownable, ReentrancyGuard, Configurable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address USDT;
    struct Pool {
        // pool name
        string name;
        // creator of the pool
        address poolCreator;
        // the timestamp in seconds the pool will open
        uint256 startAuctionAt;
        // the timestamp in seconds the pool will be closed
        uint256 endAuctionAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint256 claimAuctionFundsAt;
        // whether or not whitelist is enable
        bool enableWhiteList;
        uint256 maxAmountPerWallet;
        bool onlySeedHolders;
        address sellToken;
        // Totol supply
        uint256 amountOfSellToken;
        //Swap ratio
        uint256 swapRatio;
        bool isUSDT;
        address poolCurrency;
    }

    Pool[] internal pools;

    mapping(uint256 => address) public poolOwners;

    mapping(address => uint256) public ethCollectedForPoolOwner;

    mapping(address => uint256) public ehterStakedByUsers;

    mapping(uint256 => uint256) public sellTokenCollected;

    mapping(uint256 => address[]) public whiteLists;

    uint256[] public poolBalances;

    event LiqiudityPoolCreated(
        uint256 indexed index,
        address indexed sender,
        Pool pool
    );
    event LiqiudityPoolEnded(
        uint256 indexed index,
        address indexed sender,
        Pool pool
    );
    event FundsAdded(uint256 indexed index, address indexed sender, Pool pool);
    event FundsRemoved(
        uint256 indexed index,
        address indexed sender,
        Pool pool
    );
    event FundsWithdrawn(
        uint256 indexed index,
        address indexed sender,
        uint256 indexed amount
    );
    event FeeCalculated(
        uint256 indexed index,
        address indexed sender,
        uint256 indexed amount
    );
    event TokensSwaped(
        uint256 indexed index,
        address indexed sender,
        uint256 indexed price
    );

    constructor(
        uint256 trasnctionFee,
        uint256 seedTransactionFee,
        uint256 seedTokenMinHolding,
        address seedTokenAddress,
        address seedHubWallet,
        address usdt
    )
        Configurable(
            trasnctionFee,
            seedTransactionFee,
            seedTokenMinHolding,
            seedTokenAddress,
            seedHubWallet
        )
    {
        USDT = usdt;
    }

    function calculateFee(
        uint256 funds,
        uint256 txFee,
        uint256 div
    ) public pure returns (uint256) {
        require((funds * txFee) / div > 0, "Too small");
        uint256 deductedFee = (funds * txFee) / div;
        return deductedFee;
    }

    function create(
        string memory name,
        address sellToken,
        uint256 swapRatio,
        uint256 maxAmountPerWallet,
        uint256 amountOfSellToken,
        uint256[] memory time,
        bool onlySeedHolders,
        bool enableWhiteList,
        bool isUSDT,
        address[] memory whiteList
    ) public nonReentrant {
        require(tx.origin == msg.sender, "disallow contract caller");
        require(amountOfSellToken != 0, "invalid amountTotal0");
        require(time[0] > block.timestamp, "invalid openAt");
        require(time[1] > time[0], "invalid closeAt");
        require(time[2] > time[1], "invalid claim date");
        require(time[1] > block.timestamp, "invalid close time");
        require(time[2] > block.timestamp, "invalid claim date");
        require(bytes(name).length <= 15, "length of name is too long");

        uint256 index = pools.length;
        poolBalances[index] = amountOfSellToken;
        if (enableWhiteList) {
            whiteLists[index] = whiteList;
        }

        Pool memory pool;

        pool.name = name;
        pool.sellToken = sellToken;
        pool.startAuctionAt = time[0];
        pool.endAuctionAt = time[1];
        pool.claimAuctionFundsAt = time[2];
        pool.maxAmountPerWallet = maxAmountPerWallet;
        pool.onlySeedHolders = onlySeedHolders;
        pool.enableWhiteList = enableWhiteList;
        pool.poolCreator = msg.sender;
        pool.swapRatio = swapRatio;
        pool.maxAmountPerWallet = maxAmountPerWallet;
        pool.isUSDT = isUSDT;

        pools.push(pool);
        poolOwners[index] = msg.sender;
        LiqiudityPoolCreated(index, msg.sender, pool);

        IERC20(pool.sellToken).transferFrom(
            msg.sender,
            address(this),
            amountOfSellToken
        );

        uint256 decimals = ERC20(pool.sellToken).decimals();
        sellTokenCollected[index] = amountOfSellToken * 10**decimals;
        FundsAdded(index, pool.poolCreator, pool);
    }

    function swapToken(uint256 index, uint256 amount)
        internal
        doesPoolExists(index)
    {
        Pool memory pool = pools[index];

        if (pool.onlySeedHolders) {
            require(
                IERC20(_config.seedTokenAddress).balanceOf(msg.sender) >
                    _config.seedTokenMinHolding,
                "This pool is only avalible for seed token holders"
            );
        }

        if (pool.enableWhiteList) {
            require(
                isAddressInWhiteList(msg.sender, index),
                "Address not in whitelist"
            );
        }

        uint256 balance = IERC20(pool.sellToken).balanceOf(address(this));
        // uint256 decimals = ERC20(pool.sellToken).decimals();

        require(balance > amount, "ERC20: transfer amount exceeds balance");
        ehterStakedByUsers[msg.sender] = amount;
        poolBalances[index] = poolBalances[index] - amount;
        sendFundsToPoolCreator(index);
    }

    function userWithDrawFunction(uint256 index)
        public
        isPoolReadyForClaim(index)
    {
        Pool memory pool = pools[index];

        require(
            ehterStakedByUsers[msg.sender] != 0,
            "Caller has no funds staked"
        );

        IERC20(pool.sellToken).approve(
            address(this),
            ehterStakedByUsers[msg.sender]
        ); // ehterStakedByUsers price against address
        IERC20(pool.sellToken).transfer(
            msg.sender,
            ehterStakedByUsers[msg.sender]
        );
        TokensSwaped(index, msg.sender, ehterStakedByUsers[msg.sender]);
        ehterStakedByUsers[msg.sender] = 0;
    }

    function sendFundsToPoolCreator(uint256 index) public {
        Pool memory pool = pools[index];
        uint256 funds = ethCollectedForPoolOwner[pool.poolCreator];
        // require funds greater than balance of tusdt
        require(
            funds - _config.seedTransactionFee > 0,
            "Funds too small for transaction"
        );

        require(
            funds - _config.trasnctionFee > 0,
            "Funds too small for transaction"
        );

        uint256 fee;

        if (pool.onlySeedHolders) {
            fee = calculateFee(funds, _config.seedTransactionFee, 10000);

            funds = funds.sub(fee);
            if (pool.isUSDT) {
                IERC20(USDT).approve(address(this), fee);
                IERC20(USDT).transfer(_config.seedHubWallet, fee);
            } else {
                payable(_config.seedHubWallet).transfer(fee);
            }
        } else {
            fee = calculateFee(funds, _config.trasnctionFee, 10000);

            funds = funds.sub(fee);
            if (pool.isUSDT) {
                IERC20(USDT).approve(address(this), fee);
                IERC20(USDT).transfer(_config.seedHubWallet, fee);
            } else {
                payable(_config.seedHubWallet).transfer(fee);
            }
        }

        require(funds > 0, "Not enough funds to transfer");

        if (!pool.isUSDT) {
            payable(pool.poolCreator).transfer(funds);
        }

        if (pool.isUSDT) {
            require(
                funds <= IERC20(USDT).balanceOf(address(this)),
                "Not enough funds for usdt please contact support"
            );
            IERC20(USDT).approve(address(this), funds);
            IERC20(USDT).transfer(msg.sender, funds);
        }

        ethCollectedForPoolOwner[pool.poolCreator] = 0;
        FundsWithdrawn(index, pool.poolCreator, funds);
        FeeCalculated(index, pool.poolCreator, fee);
    }

    function getPoolByIndex(uint256 index) public view returns (Pool memory) {
        return pools[index];
    }

    function getAllPools() public view returns (Pool[] memory) {
        return pools;
    }

    function isAddressInWhiteList(address sender, uint256 index)
        private
        view
        returns (bool)
    {
        address[] memory whitelist = whiteLists[index];

        require(whitelist.length > 0, "No whitelist in this pool");

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == sender) return true;
        }

        return false;
    }

    function withdrawUnSoldTokens(uint256 index)
        public
        isPoolReadyForClaim(index)
    {
        require(msg.sender == pools[index].poolCreator, "Not creator of pool");
        require(poolBalances[index] > 0, "Pool balance is zero");
        IERC20(pools[index].sellToken).approve(
            address(this),
            poolBalances[index]
        ); // ehterStakedByUsers price against address

        IERC20(pools[index].sellToken).transfer(
            msg.sender,
            poolBalances[index]
        );
    }

    modifier doesPoolExists(uint256 index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier isPoolClosed(uint256 index) {
        require(
            pools[index].endAuctionAt > block.timestamp,
            "this pool is closed"
        );
        _;
    }

    modifier isPoolOpen(uint256 index) {
        require(
            pools[index].endAuctionAt < block.timestamp,
            "this pool is still open"
        );
        _;
    }

    modifier isPoolReadyForClaim(uint256 index) {
        require(
            pools[index].claimAuctionFundsAt < block.timestamp,
            "this pool is not ready to be claimed"
        );
        _;
    }
}
