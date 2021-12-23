//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Configurable is Ownable {
    struct Config {
        uint256 trasnctionFee;
        address seedTokenAddress;
        address fixedSwapContract;
        address boundedSaleContract;
        address auctionContract;
        address reverseAuction;
    }

    Config private config;

    uint256 index;

    constructor(Config memory _config) {
        config = _config;
    }

    function updateTransactionFee(uint256 txFee) public onlyOwner {
        config.trasnctionFee = txFee;
    }

    function updateSeedAddress(address Seed) public onlyOwner {
        config.seedTokenAddress = Seed;
    }

    function getTransactionFee() public view returns (uint256) {
        return config.trasnctionFee;
    }

    function getSeedAddress() public view returns (address) {
        return config.seedTokenAddress;
    }
}
