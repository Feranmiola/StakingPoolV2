// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMonthPools{
    function recieveTokens(address _token, uint amount) external;
}

contract MotherPool is Initializable{

    address admin;
    IERC20Upgradeable public stakeToken;

    //Tokens
    address[] tokenAddresses;
    address[] successAddress;

    mapping(IERC20Upgradeable => uint256) tokenBalances;
    mapping(uint256 => uint256) successfulPresale;
    mapping(IERC20Upgradeable => uint256) tokenTimestamp;
    mapping(uint256 => mapping(uint256 => address)) IndexAddress;
    mapping(uint256 => mapping(IERC20Upgradeable => uint256)) successfulBalances;

    uint successCount;
    uint public lastTime;  
    uint public index;
    uint public newtime;
    
    //external
    uint256 public feesWithdrawal;
    uint256 public claim_time;
    uint256 public Mimimumhsn1;
    uint256 public Mimimumhsn3;
    uint256 public Mimimumhsn6;
    
 

    event tokensRecieved(address indexed Token, uint amount);
    event DistributedTokens(address indexed pool, uint amount);
    event withdrawn(address reciever, IERC20Upgradeable indexed tokena, uint amounta, IERC20Upgradeable indexed tokenb, uint amountb);
    event stringMessage(string message);

    function initialize() external initializer{
        admin = payable(msg.sender);
        stakeToken = IERC20Upgradeable(0x8ee8818eE9508b7bAD5197Ffd2466e02e8795515);
        lastTime = block.timestamp;
        Mimimumhsn1 = 100e18;
        Mimimumhsn3 = 100e18;
        Mimimumhsn6 = 100e18;

    }

    //setter functions

    function setFees(uint WithdrawalFee) external {
        feesWithdrawal = WithdrawalFee;
    }

    function setClaimTime(uint claimTime) external{
        claim_time = claimTime;
    }

    function setHsn(
        uint256 _Mimimumhsn1,
        uint256 _Mimimumhsn3,
        uint256 _Mimimumhsn6
    
    ) external {
        
        require(msg.sender == admin, "NA");//Not Admin

        Mimimumhsn1 = _Mimimumhsn1;
        Mimimumhsn3 = _Mimimumhsn3;
        Mimimumhsn6 = _Mimimumhsn6;
     
    }

  
    
    function getStakeToken() external view returns(IERC20Upgradeable){
        return stakeToken;
    }
    function getClaimTime() external view returns(uint){
        return claim_time;
    }
    function getWIthdrawalFees() external view returns(uint){
        return feesWithdrawal;
    }
    function getMinimumStake1() external view returns(uint){
        return Mimimumhsn1;
    }
    
     function getMinimumStake3() external view returns(uint){
        return Mimimumhsn3;
    }
    
     function getMinimumStake6() external view returns(uint){
        return Mimimumhsn6;
    }
    function getAdmin() external view returns(address){
        return admin;
    }
    
    //called from presale contract

    function receiveTokenFee(address _token, uint256 amount) external{

        IERC20Upgradeable token = IERC20Upgradeable(_token);

        index++;

        tokenAddresses.push(_token);

        tokenBalances[token] += amount;

        successfulPresale[index] = block.timestamp;

        IndexAddress[index][block.timestamp] = _token;

        emit tokensRecieved(_token, amount);

    }


    function setNewTime() public{

        newtime = lastTime + claim_time;
        
        for(uint i = 1; i <= index; i++){

            if(successfulPresale[i] >= lastTime){
                if(successfulPresale[i] <= newtime){

                successAddress.push(IndexAddress[i][successfulPresale[i]]);
            
                }
            }
            
        }

        successCount = successAddress.length;
    }



    function distribute(address _month1, address _month2, address _month3) external {
        require(msg.sender == admin, "NA");

        setNewTime();


            if(successCount >= 2 && successCount <= 10){
            lessThanTen(_month2, _month3);    
                        
            }

            if(successCount > 10){
                greaterThanTen( _month1, _month2, _month3);
            }


         for(uint i =1; i <= tokenAddresses.length; i++){
            if(successfulPresale[i -1] >= lastTime && successfulPresale[i -1] <= newtime){
    

            }
        }


        for(uint i = 1; i <= successCount; i++){

                IERC20Upgradeable token = IERC20Upgradeable(successAddress[i -1]);

                delete successfulPresale[i -1];
                delete tokenBalances[token];      
                        
                
            }
            
        

        delete successCount;
        delete index;

        lastTime = block.timestamp;
        delete successAddress;
      
    
}


    function greaterThanTen(address _month1, address _month2, address _month3) internal{
             uint tokenPercent;
             uint tokenPercent2;
             uint tokenPercent3;

             for(uint i = 1; i<= successCount; i++){
                 
           IERC20Upgradeable token = IERC20Upgradeable(successAddress[i -1]);

                tokenPercent = 1000 * token.balanceOf(address(this))/10000;
                tokenPercent2 = 6000 * token.balanceOf(address(this))/10000;
                tokenPercent3 = 3000 * token.balanceOf(address(this))/10000;

               IMonthPools(_month1).recieveTokens(successAddress[i -1],tokenPercent);
               IMonthPools(_month2).recieveTokens(successAddress[i -1],tokenPercent3);
               IMonthPools(_month3).recieveTokens(successAddress[i -1],tokenPercent2);

                token.transfer(_month1, tokenPercent);
                token.transfer(_month2, tokenPercent3);
                token.transfer(_month3, tokenPercent2);
                
                 emit DistributedTokens(_month3, tokenPercent2);
                emit DistributedTokens(_month2, tokenPercent3);
                emit DistributedTokens(_month1, tokenPercent);
             }


    }



    function lessThanTen(address _month2, address _month3) internal{
            
        uint tokenPercent; 
   
            for(uint i = 1; i<= successCount; i++){

           IERC20Upgradeable token = IERC20Upgradeable(successAddress[i -1]);             
                tokenPercent = 5000 * token.balanceOf(address(this))/10000;
          
                token.transfer(_month2, tokenPercent);
                token.transfer(_month3, tokenPercent);   

                 IMonthPools(_month2).recieveTokens(successAddress[i -1],tokenPercent);
                 IMonthPools(_month3).recieveTokens(successAddress[i -1],tokenPercent);    

                emit DistributedTokens(_month2, tokenPercent);
                emit DistributedTokens(_month3, tokenPercent);  
            }
    }

    

    function AdminWithdrawal() external {
        require(msg.sender == admin, "NA");

        uint debit = stakeToken.balanceOf(address(this));

        stakeToken.transfer(admin, debit);

        // emit withdrawn(admin, stakeToken, ssnBalance, hsn, hsnBalance);
    }

 
}