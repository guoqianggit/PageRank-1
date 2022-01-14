// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Isenator{
    function epochId() external view returns(uint);
    function executerId() external view returns(uint);
    function getExecuter() external view returns(address);
    function isSenator(address) external view returns(bool);
}

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract ledger is Initialize {
    address public senator;

    //提案状态:{等待，成功，失败}
    enum Result{PENDING, SUCCESS, FAILED}

     //记账提案
    struct ledgerProposal{
        uint epochId;                         //共识周期
        address user;                         //用户
        uint amount;                          //提取金额
        address proposer;                     //提案人
        uint proposalTime;                    //提案时间
        uint assentor;                        //赞同者数量
        uint unAssentor;                      //反对者数量
        Result result;                        //共识结果
    }


    //账本
    mapping (uint => ledgerProposal[]) public ledgers;
    //提案序号
    uint public nonce;

    event SendLedgerProposal(uint indexed executerId, uint nonce, address user, uint amount);
    
    modifier onlyExecuter(){
        require(Isenator(senator).getExecuter() == msg.sender, "access denied: only Executer");
        _;
    }

    modifier onlySentor(){
        require(Isenator(senator).isSenator(msg.sender), "access denied: only senator");
        _;

    }

    function initialize(address _senator) external init{
        senator=_senator;
    }
    
    //发起快照提案
    function sendLedgerProposal(address _user, uint _amount) external onlyExecuter{
        uint _epochId = Isenator(senator).epochId();
        uint _executerId = Isenator(senator).executerId();
        if(ledgers[_executerId].length == 0){
            //TODO:验证快照共识已经完成(若快照共识未完成责实时记账会出现差异)
            //该验证交由PR节点进行验证
            nonce = 0;
        }else{
            //TODO：验证上一笔记账共识已完成
            require(ledgers[_executerId][nonce].result != Result.PENDING, "The latest proposal has no resolution");
            nonce++;
        }

        ledgers[_executerId].push(ledgerProposal(
            {
                epochId: _epochId,
                user: _user,
                amount: _amount,
                proposer: msg.sender,
                proposalTime: block.timestamp,
                assentor: 0,
                unAssentor: 0,
                result: Result.PENDING
            }
        ));

        emit SendLedgerProposal(_executerId, nonce, _user, _amount);
    }
    
     //获取最新提案
    function latestLedgerProposal() external view returns(uint epochId, address user, uint amount, address proposer, uint proposalTime, uint result){
        ledgerProposal memory lp = ledgers[Isenator(senator).executerId()][nonce];
        return(lp.epochId, lp.user, lp.amount, lp.proposer, lp.proposalTime, uint(lp.result));
    }
    
    //表决提案
    function vote(bool v) external onlySentor{
        uint executerId = Isenator(senator).executerId(); 
        require(ledgers[executerId][nonce].result == Result.PENDING,"Reached a consensus");
        if(v) {
            ledgers[executerId][nonce].assentor++;
            if (ledgers[executerId][nonce].assentor>=6) ledgers[executerId][nonce].result = Result.SUCCESS;
        }else{
            ledgers[executerId][nonce].unAssentor++;
            if (ledgers[executerId][nonce].unAssentor>=6) ledgers[executerId][nonce].result = Result.FAILED;
        }
    }

    //最新提案是否已完成表决
    function isResolution() external view returns(bool){
         uint executerId = Isenator(senator).executerId(); 
         if (ledgers[executerId][nonce].result != Result.PENDING) {
             return true;
         }else{
             return false;
         }
    }
}