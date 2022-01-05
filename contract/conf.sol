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
    address public vote;
    address public senator;
    address public consensus;
    address public proposal;
    address public award;
    address public punishment;

    modifier onlyConsensus(){
        require(msg.sender == consensus, "only consensus");
        _;
    }

    function initialize(address _pledge, address _vote, address _senator, address _consensus, address _proposal, address _award, address _punishment) external init{
        (pledge, vote, senator, consensus, proposal, award, punishment) = (_pledge, _vote, _senator, _consensus, _proposal, _award, _punishment);
    }

    //调试时测试，升级本合约情况是否合法。
    function upgrad(address target, address newLogic) external onlyConsensus{
        upgradeable(target).upgrad(newLogic);
    }
}