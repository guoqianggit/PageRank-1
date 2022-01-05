// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Ipledge{
    function nodeRank(uint begin, uint end)external returns(address[] calldata);
}

interface Iconf{
    function pledge()external view returns(address);
    function punishment()external view returns(address);
}

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract senator is Initialize {
    uint public epochId;                       //共识周期
    uint public epochIndate;                   //本届共识集有效期
    uint public executerId;                    //执法者序号
    uint public executerIndate;                //执法者有效期
    uint public executerindex;                 //执法者在共识集中的序号
    
    address[] public senators;                 //当前共识集
    address public conf;                       //配置合约

    event UpdateSenator(uint indexed _epochId, address[] _sentors, uint _epochIndate);
    event UpdateExecuter(uint indexed _executerId, address _executer, uint _executerIndate);


    function initialize(address _conf) external init{
        conf = _conf;

        senators = Ipledge(Iconf(conf).pledge()).nodeRank(0,10);
        epochIndate = block.timestamp + 7 days;
        executerIndate = block.timestamp + 1 days;
    }

    function _getSenator() internal view returns(address) {
         return senators[executerId];
    }
    
    //查询执法者
    function getSenator() external view returns(address){
        return _getSenator();
    }

    function _getNextSenator() internal view returns(address) {
        if (executerindex == senators.length) return senators[0]; 
        return senators[executerId+1];
    }
    
    //查询执法者继任人
    function getNextSenator() external view returns(address) {
        return _getNextSenator();
    }

    function _updateSenator() internal {
        address[] memory newSenators = Ipledge(Iconf(conf).pledge()).nodeRank(0,10);
        epochId++;
        epochIndate += 7 days;
        senators = newSenators;
        executerId++;
        executerId = 0;
        executerIndate += 1 days;

        emit UpdateSenator(epochId, senators, epochIndate);
    }

    //更新共识集
    function updateSenator() external {
        require(block.timestamp >= epochIndate, "unexpired");
        _updateSenator();

        //TODO: 添加奖励机制
    }


    function _updateExecuter() internal {
        if (executerindex == senators.length){
            executerindex = 0;
        }else{
            executerindex++;
        }
        
        executerId++;
        executerIndate += 1 days;

        emit UpdateExecuter(executerId, _getNextSenator(), executerIndate);
    }


    //更新执法者
    function updateExecuter() external {
        if(msg.sender != Iconf(conf).punishment()){
            require(block.timestamp >= executerIndate, "unexpired");
        }
        
        if (block.timestamp >= epochIndate) {
            _updateSenator();
        }else{
            _updateExecuter();
        }

        //TODO: 添加奖励机制
    }
}