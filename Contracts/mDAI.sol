//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/contracts/ERC20";

contract DaiToken is ERC20PresetFixedSupply {
    constructor()
        ERC20PresetFixedSupply("Mock DAI Token", "mDAI", 1000000000, msg.sender)
    {}
}
