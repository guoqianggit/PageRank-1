// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract consensus is Initialize {
    address public conf;
    
    function initialize(address _conf) external init{
        conf = _conf;
    }



}