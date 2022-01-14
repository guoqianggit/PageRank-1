// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface upgradeable{
    function upgrad(address newLogic) external returns(bool);
}

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Conf is Initialize {
    address public pledge;
    address public snapshoot;
    address public upgrade;
    address public senator;
    address public poc;
    address public developer;

    function initialize(address _pledge, address _snapshoot, address _upgrade, address _senator, address _poc) external init{
        (pledge, snapshoot, upgrade, senator, poc, developer) = (_pledge, _snapshoot, _upgrade, _senator, _poc, msg.sender);
    }

    //调试时测试，升级本合约情况是否合法。
    //pr需要增加人工审核流程（杜绝自动授权）
    function upgrad(address target, address newLogic) external {
        upgradeable(target).upgrad(newLogic);
    }
}