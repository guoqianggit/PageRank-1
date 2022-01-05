// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy.sol";

contract TraderPorxy is basePorxy{
    constructor(address consensus ,address impl) {
        _setAdmin(consensus);
        _setLogic(impl);
    }
}