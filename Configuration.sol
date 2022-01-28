//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Configurable is Ownable {
    struct Config {
        uint256 trasnctionFee;
        uint256 seedTransactionFee;
        uint256 seedTokenMinHolding;
        address seedTokenAddress;
        address seedHubWallet;
        address[] whitelist;
    }

    Config public _config;

    constructor(
        uint256 trasnctionFee,
        uint256 seedTransactionFee,
        uint256 seedTokenMinHolding,
        address seedTokenAddress,
        address seedHubWallet
    ) {
        _config.trasnctionFee = trasnctionFee;
        _config.seedTokenMinHolding = seedTokenMinHolding;
        _config.seedTransactionFee = seedTransactionFee;
        _config.seedTokenAddress = seedTokenAddress;
        _config.seedHubWallet = seedHubWallet;
    }

    function updateWhiteList(address[] memory whitelist) public onlyOwner {
        _config.whitelist = whitelist;
    }

    function updateTransactionFee(uint256 txFee) public onlyOwner {
        _config.trasnctionFee = txFee;
    }

    function updateSeedTransactionFee(uint256 txFee) public onlyOwner {
        _config.seedTransactionFee = txFee;
    }

    function updateSeedAddress(address Seed) public onlyOwner {
        _config.seedTokenAddress = Seed;
    }

    function getTransactionFee() public view returns (uint256) {
        return _config.trasnctionFee;
    }

    function getSeedAddress() public view returns (address) {
        return _config.seedTokenAddress;
    }
}
