// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Iconf{
    function senator() external view returns(address);
    function poc() external view returns(address);
}

interface Isenator{
    function epochId() external view returns(uint);
    function executerId() external view returns(uint);
    function executerIndate() external view returns(uint);
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

contract snapshoot is Initialize {
    address public conf;

    //快照集
    snapshootProposal[] public snapshoots;

    //提案状态:{等待，成功，失败}
    enum Result{PENDING, SUCCESS, FAILED}
    
    //快照提案（每天提案一次）
    struct snapshootProposal{
        uint epochId;                         //共识周期
        uint executerId;                      //执法者ID（第几任执法者）
        string prHash;                        //PR计算结果文件Hash
        string prId;                          //文件在IPFS上的ID
        address proposer;                     //提案人（执法者）
        uint proposalTime;                    //提案时间
        uint assentor;                        //赞同者数量
        uint unAssentor;                      //反对者数量
        Result result;                        //共识结果
    }

    event SendSnapshootProposal(uint indexed executerId, address executer, string prHash, string prId);

    modifier onlyExecuter(){
        require(Isenator(Iconf(conf).senator()).getExecuter() == msg.sender, "access denied: only Executer");
        _;
    }

    modifier onlySentor(){
        require(Isenator(Iconf(conf).senator()).isSenator(msg.sender), "access denied: only senator");
        _;
    }

    modifier onlyPoc(){
        require(Iconf(conf).poc() == msg.sender, "access denied: only poc");
        _;
    }

   function initialize(address _conf) external init{
        conf = _conf;
    }
    
    //发起快照提案
    function sendSnapshootProposal(string memory _prHash, string memory _prId) external onlyExecuter{
        require(isResolution(), "The latest proposal has no resolution");
        require(snapshoots[snapshoots.length -1].proposer != msg.sender, "resubmit");

        uint _epochId = Isenator(Iconf(conf).senator()).epochId();
        uint _executerId = Isenator(Iconf(conf).senator()).executerId();
        snapshoots.push(snapshootProposal(
            _epochId,
            _executerId,
            _prHash,
            _prId,
            msg.sender,
            block.timestamp,
            0,
            0,
            Result.PENDING
        ));   

        emit SendSnapshootProposal(_executerId, msg.sender, _prHash, _prId);
    }
    
     //获取最新提案
    function latestSnapshootProposal() external view returns(uint epochId, uint executerId, string memory prHash, string memory prId, address proposer, uint proposalTime, uint result){
        snapshootProposal memory sp = snapshoots[snapshoots.length -1];
        return(sp.epochId, sp.executerId, sp.prHash, sp.prId, sp.proposer, sp.proposalTime, uint(sp.result));
    }

    //表决提案
    function vote(bool v) external onlySentor{
        require(!isResolution(), "Reached a consensus");
        if(v) {
            snapshoots[snapshoots.length-1].assentor++;
            if (snapshoots[snapshoots.length-1].assentor>=6) snapshoots[snapshoots.length-1].result = Result.SUCCESS;
        }else{
            snapshoots[snapshoots.length-1].unAssentor++;
            if (snapshoots[snapshoots.length-1].unAssentor>=6) snapshoots[snapshoots.length-1].result = Result.FAILED;
        }
    }

    //一票否决
    function veto() external onlyPoc{
        snapshoots[snapshoots.length-1].result = Result.FAILED;
    }


    //最新提案是否已完成表决
    function isResolution() public view returns(bool){
         if (snapshoots[snapshoots.length-1].result != Result.PENDING) {
             return true;
         }else{
             return false;
         }
    }

    //执法者是否违规
    function  isOutLine() external view returns(bool){
        if (snapshoots[snapshoots.length -1].executerId != Isenator(Iconf(conf).senator()).executerId() &&
            block.timestamp + 22 hours > Isenator(Iconf(conf).senator()).executerIndate()){
            return true;
        }else{
            return false;
        }
    }
}