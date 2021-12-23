//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Configuration"
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LP_ICO  is Ownable,ReentrancyGuard,Configuration{
  
    using SafeERC20 for IERC20; 

    struct Pool {
        // pool name
        string name;
        // creator of the pool
        address  poolCreator;
        // the timestamp in seconds the pool will open
        uint startAuctionAt;
        // the timestamp in seconds the pool will be closed
        uint endAuctionAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAuctionFundsAt;
        // whether or not whitelist is enable
        bool enableWhiteList;

        uint maxAmountPerWallet;
        bool onlySeedHolders;
        address sellToken;
       
       // Totol supply
        uint amountOfSellToken;
       
       //Swap ratio
        uint256 swapRatio;
    }
    

    struct PoolReq {
        // pool name
        string name;
        address sellToken;
        uint256 swapRatio;
        uint maxAmountPerWallet;
        uint amountOfSellToken;
        // the timestamp in seconds the pool will open
        uint startAuctionAt;
        // the timestamp in seconds the pool will be closed
        uint endAuctionAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAuctionFundsAt;
        // whether or not whitelist is enable
        bool onlySeedHolders;
        bool enableWhiteList;
 
    }


    Pool[] internal pools;

    
    mapping(uint256=>address) public poolOwners;
    
    mapping(address=>uint256) public fundsCollected;
    
    mapping(uint=>uint256) public fundsAllocated;


    event LiqiudityPoolCreated(uint indexed index, address indexed sender,Pool pool);
    event LiqiudityPoolEnded(uint indexed index, address indexed sender,Pool pool); 
    event FundsAdded(uint indexed index, address indexed sender,Pool pool);
    event FundsRemoved(uint indexed index, address indexed sender,Pool pool);
    event FundsWithdrawn(uint indexed index, address indexed sender,Pool pool);
    event TokensSwaped(uint indexed index, address indexed sender,uint indexed price);

    constructor() {}

    function create(PoolReq memory req) internal 
    nonReentrant
    {
        
        require(tx.origin == msg.sender, "disallow contract caller");
        require(req.amountOfSellToken != 0, "invalid amountTotal0");
        require(req.startAuctionAt < block.timestamp, "invalid openAt");
        require(req.endAuctionAt > req.startAuctionAt, "invalid closeAt");
        require(req.claimAuctionFundsAt > req.endAuctionAt, "invalid claim date");
        require(req.endAuctionAt> block.timestamp, "invalid close time");
        require(req.claimAuctionFundsAt> block.timestamp, "invalid claim date");
        require(bytes(req.name).length <= 15, "length of name is too long");
        uint index = pools.length;
        Pool memory pool ;

        pool.name = req.name;
        pool.sellToken = req.sellToken;
        pool.startAuctionAt = req.startAuctionAt;
        pool.endAuctionAt = req.endAuctionAt;
        pool.claimAuctionFundsAt = req.claimAuctionFundsAt;
        pool.maxAmountPerWallet = req.maxAmountPerWallet;
        pool.onlySeedHolders = req.onlySeedHolders;
        pool.enableWhiteList = req.enableWhiteList;
        pool.poolCreator = msg.sender;
        pool.swapRatio = req.swapRatio;
        pool.maxAmountPerWallet= req.maxAmountPerWallet;

        pools.push(pool);
        poolOwners[index] = msg.sender;
        LiqiudityPoolCreated(index,msg.sender,pool);
        
        IERC20(pool.sellToken).transferFrom(msg.sender,address(this),req.amountOfSellToken);
        fundsAllocated[index] = pool.amountOfSellToken;
        FundsAdded(index,pool.poolCreator,pool);
    }


    function swapToken(uint index, uint amount,uint price) internal 
        doesPoolExists(index)
    {
        Pool memory pool = pools[index];
        
        require(amount < pool.maxAmountPerWallet,"Cannot spend more then that maximum allocation");
                
        IERC20(pool.sellToken).approve( address(this),amount);
        IERC20(pool.sellToken).transfer( msg.sender,amount);                        
        TokensSwaped(index, msg.sender,price);

    }
    
    function withdraw(uint index) 
    internal
    nonReentrant
    isPoolReadyForClaim(index)
    {
        
        Pool memory pool = pools[index];

        require(pool.poolCreator == msg.sender,"Only pool owner can widthdrawFunds");
        uint256 funds = fundsCollected[pool.poolCreator];
        payable(pool.poolCreator).transfer(funds);
        fundsCollected[pool.poolCreator] = 0;
    } 


    function getAllPools() public view returns(Pool[] memory){
        return pools;
    }
 

    modifier doesPoolExists(uint index){
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier  isPoolClosed(uint index){
        require(pools[index].endAuctionAt > block.timestamp, "this pool is closed");
        _;
    }

    modifier  isPoolOpen(uint index){
        require(pools[index].endAuctionAt < block.timestamp, "this pool is still open");
        _;
    }
    
    modifier  isPoolReadyForClaim(uint index){
        require(pools[index].claimAuctionFundsAt < block.timestamp, "this pool is not ready to be claimed");
        _;
    }
    
 

}