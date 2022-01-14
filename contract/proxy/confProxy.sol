// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy.sol";

contract TraderProxy is baseProxy{
    constructor(address consensus ,address impl) {
        _setAdmin(consensus);
        _setLogic(impl);
    }
}