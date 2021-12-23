//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";


import "./LP_ICO.sol";

contract FixedSwap is LP_ICO {


    using SafeMath for uint;

    constructor(){
        
    }

    function createLiquidityPool(PoolReq memory req) public{
            create(req);
    }

    function calculatePrice(uint256 amount,uint256 swapRatio) public pure  returns(uint256){

        uint256 basePrice = 10**18;

        uint256 ratioConstant = basePrice.div(swapRatio);

        uint256 price.div(ratioConstant) = amount ;

        return price;

    }

    function getAvalibleFunds(uint index) internal view returns(uint256){
            return fundsAllocated[index];
    }

    function withDrawFunds(uint index) external {
        withdraw(index); 
    } 
    
    function addBid(uint index,uint amount) 
    external 
    payable
    isPoolClosed(index)
    {

        Pool memory pool = pools[index];
        
        uint price = calculatePrice(amount,pool.swapRatio);

        require(msg.value==(1 wei)*price,"Invalid funds");
        swapToken(index,amount,price);

        fundsCollected[pool.poolCreator] += msg.value;
        fundsAllocated[index] -= amount;

    }
    
    modifier checkIfTransactionIsPossible(uint index, uint amount){
    
        uint amoutOfFunds = fundsAllocated[index];

        require(amoutOfFunds.sub(amount) >0 ,"Insufficient Funds in the pool for this transaction");
        _;
        
    }




}