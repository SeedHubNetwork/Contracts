//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DaiToken is ERC20 {
    constructor() ERC20("Mock DAI Token", "mDAI") {}

    function sendTo(address send) public {
        _mint(send, 1000000000000);
    }
}
