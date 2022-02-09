//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LP_ICO.sol";

contract FixedSwap is LP_ICO {
    using SafeMath for uint256;

    constructor(
        uint256 trasnctionFee,
        uint256 seedTransactionFee,
        uint256 seedTokenMinHolding,
        address seedTokenAddress,
        address seedHubWallet,
        address usdt
    )
        LP_ICO(
            trasnctionFee,
            seedTransactionFee,
            seedTokenMinHolding,
            seedTokenAddress,
            seedHubWallet,
            usdt
        )
    {}

    function createLiquidityPool(Pool memory pool, address[] memory whiteList)
        public
    {
        create(pool, whiteList);
    }

    function calculateAmount(
        uint256 price,
        uint256 swapRatio,
        uint256 decimals
    ) public pure returns (uint256) {
        uint256 amount = price.mul(swapRatio * 10**decimals);

        if (decimals < 18) {
            amount = amount.div(1 * 10**decimals);
        } else {
            amount = amount.div(1 * 10**18);
        }

        return amount;
    }

    function getAvalibleFunds(uint256 index) internal view returns (uint256) {
        return sellTokenCollected[index];
    }

    function addBid(uint256 index, uint256 amount)
        external
        payable
        isPoolClosed(index)
    {
        Pool memory pool = pools[index];

        require(
            msg.value <= pool.maxAmountPerWallet,
            "Cannot spend more then that maximum allocation"
        );

        uint256 decimals = ERC20(pool.sellToken).decimals();
        uint256 calculatedAmount = calculateAmount(
            msg.value,
            pool.swapRatio,
            decimals
        );

        require(calculatedAmount > 0, "Too small of an amount to transact");

        require(amount == calculatedAmount, "Amount is incorrect");

        ethCollectedForPoolOwner[pool.poolCreator] += msg.value;
        sellTokenCollected[index] -= amount;

        swapToken(index, amount);
    }

    function addBidUSDT(
        uint256 index,
        uint256 amount,
        uint256 price
    ) internal isPoolClosed(index) {
        Pool memory pool = pools[index];

        require(
            price <= pool.maxAmountPerWallet,
            "Cannot spend more then that maximum allocation"
        );

        require(pool.isUSDT, "pool not  for USDT");

        uint256 decimals = ERC20(pool.sellToken).decimals();
        uint256 calculatedAmount = calculateAmount(
            price,
            pool.swapRatio,
            decimals
        );

        require(calculatedAmount > 0, "Too small of an amount to transact");

        require(amount == calculatedAmount, "Amount is incorrect");

        ethCollectedForPoolOwner[pool.poolCreator] += price;
        sellTokenCollected[index] -= amount;

        swapToken(index, amount);
    }

    function addBidInUSDT(
        uint256 index,
        uint256 amount,
        uint256 price
    ) public payable {
        IERC20(USDT).transferFrom(msg.sender, address(this), price);
        addBidUSDT(index, amount, price);
    }

    modifier checkIfTransactionIsPossible(uint256 index, uint256 amount) {
        uint256 amoutOfFunds = sellTokenCollected[index];

        require(
            amoutOfFunds.sub(amount) > 0,
            "Insufficient Funds in the pool for this transaction"
        );
        _;
    }
}
