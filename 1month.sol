// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface iMotherPool{
    function getStakeToken() external view returns(IERC20Upgradeable);
    function getClaimTime() external view returns(uint);
    function getWIthdrawalFees() external view returns(uint);
    function getMinimumStake1() external view returns(uint);
     function getMinimumStake3() external view returns(uint);
     function getMinimumStake6() external view returns(uint);
     function getAdmin() external view returns(address);
}

contract month1 is Initializable{

    IERC20Upgradeable public stakeToken;
    address admin;

    mapping(address => uint) public contractTokenBalances;
    uint256 public feesTaken;
    address[] tokenAddresses;
    address[] recievableTokens;

    iMotherPool public MainPool;
    uint256 activeStakers;

    struct recievedTokens{
        address token;
        uint256 amount;
    }


    mapping(address => uint256) public balances;
    mapping(address => uint256) public Fullbalances;
    mapping(address => uint256) NormalBalance;
    mapping(address => uint256) public Duration;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public claimedWeek;
    mapping(address => mapping(address => uint256)) public userTokenBalances;
    mapping(address =>  bool) public finalised;
    mapping(address => uint256) updatedTime;
    mapping(address => mapping(uint => address)) public claimedTokens;
    mapping(address => uint256) public claimedNumber;
    mapping(address => uint256) public tokenBalanceaddress;
    mapping(address => uint) public timeRecived;
    mapping(address => recievedTokens[]) recievedTokensMapped;
    mapping(address => uint[]) tokenamountsarray;
    mapping(address => uint) initialStake;
    


    uint public claim_time;
    uint public WithdrawalFee;

    uint public claimNumber;
    uint256 public MimimumStake;
    bool public called;


    event Staked(address indexed staker, uint256 stakingAmount, uint256 stakingTime, uint256 Period);
    event Unstaked(address indexed unstaker, uint256 amount, uint256 unstakeTime);
    event unstakedAll(address indexed unstaker, uint256 amount);
    event claimedRewards(address indexed claimer);
    event FinalizedStaking(address indexed reciever, uint256 feeAmount);


    function initialize(address motherPool) external initializer{
        MainPool = iMotherPool(motherPool);

        stakeToken = MainPool.getStakeToken();

        claim_time = MainPool.getClaimTime();

        WithdrawalFee = MainPool.getWIthdrawalFees();

        admin = MainPool.getAdmin();

        

    }

    function updatePoolInfo() public{
        
        claim_time = MainPool.getClaimTime();

        WithdrawalFee = MainPool.getWIthdrawalFees ();
        MimimumStake = MainPool.getMinimumStake1();
        

    }

    function recieveTokens(address _token, uint amount) external{
     
        contractTokenBalances[_token] += amount;

        tokenAddresses.push(_token);
        recievableTokens.push(_token);


    }

    function stake(uint amount) external{
        updatePoolInfo();
        
        finalised[msg.sender] == false;
    
        require(amount >= MainPool.getMinimumStake1());
        
        stakeToken.transferFrom(msg.sender, address(this), amount);

        initialStake[msg.sender] +=amount;

        uint Fees = 1500 * amount/10000;

        amount -= Fees;


            Fullbalances[msg.sender] += amount;

            claimNumber = 30 days / claim_time;

            feesTaken += Fees;


            if(Duration[msg.sender] == 0){
                Duration[msg.sender] += block.timestamp;

                startTime[msg.sender] = block.timestamp;
                
                updatedTime[msg.sender] = block.timestamp;

                activeStakers ++;
            }     
            
            balances[msg.sender] += amount;
            NormalBalance[msg.sender] += amount;
            Duration[msg.sender] += 30 days;

        emit Staked(msg.sender, amount, Fees, 30 days);

    }

    function unstake(uint _amount) external{
        updatePoolInfo();
        require(NormalBalance[msg.sender] > 0, "EB");
        require(Duration[msg.sender] > block.timestamp, "AE");//Already Ended

        if(_amount == NormalBalance[msg.sender]){
            unstakeAll();
        } else{
            

         uint finalAmount =  NormalBalance[msg.sender] - _amount;

        require(finalAmount >= MimimumStake, "The final stake less than minimum");
        
        uint amount = _amount - (WithdrawalFee * balances[msg.sender] / 10000);

        balances[msg.sender] = balances[msg.sender] - amount;

        stakeToken.transfer(msg.sender, amount);
            
        
        emit Unstaked(msg.sender, amount, block.timestamp);
    }
        
    
    }

    function unstakeAll() internal {
        require(NormalBalance[msg.sender] > 0, "EB");
        
        
        uint amount = NormalBalance[msg.sender] - (WithdrawalFee * NormalBalance[msg.sender] / 10000);

        delete claimedWeek[msg.sender];
        delete NormalBalance[msg.sender];
        delete balances[msg.sender];
        delete Fullbalances[msg.sender];
        delete Duration[msg.sender];

        activeStakers--;


        stakeToken.transfer(msg.sender, amount);

        emit unstakedAll(msg.sender, amount);
        
    }

    function claimRewards() external{
        updatePoolInfo();
        require(updatedTime[msg.sender] + claim_time <= block.timestamp, "CNS");//Claiming not started 
        require(Duration[msg.sender] > block.timestamp, "AE");
        require(NormalBalance[msg.sender] > 0, "EB");//EmptyBalance
        require(claimedWeek[msg.sender] < claimNumber, "CC");//Claiming completed 


        uint256 claimingPercent = initialStake[msg.sender]  * 10000/stakeToken.balanceOf(address(this));

        claimedWeek[msg.sender] ++;

        for(uint i = 1; i<= recievableTokens.length; i++){

            uint claimmable = claimingPercent * tokenBalanceaddress[recievableTokens[i-1]]/ 10000;
            
            claimedNumber[msg.sender] ++;

            claimedTokens[msg.sender][claimedNumber[msg.sender]] = recievableTokens[i-1];

            userTokenBalances[msg.sender][recievableTokens[i-1]] = claimmable;
           
          

            recievedTokensMapped[msg.sender].push(recievedTokens({
                token : recievableTokens[i-1],
                amount : claimmable
            }));

            tokenamountsarray[msg.sender].push(userTokenBalances[msg.sender][recievableTokens[i-1]] = claimmable);

        }

        updatedTime[msg.sender] = block.timestamp;        

        emit claimedRewards(msg.sender);
    }

    function finaliseStaking() external{
        require(!finalised[msg.sender], "AF"); //Already finalised
        require(claimedWeek[msg.sender] <= claimNumber, "SNO");//Staking not over
        require(Duration[msg.sender] <= block.timestamp, "NE");//Not ended
        

        // for(uint i = 0; i <= claimedNumber[msg.sender]; i++){
        //     claimRewards();
        // }
        
        for(uint i = 1  ; i<= claimedNumber[msg.sender]; i++){

            IERC20Upgradeable __token = IERC20Upgradeable(claimedTokens[msg.sender][i]);

            uint recievable = userTokenBalances[msg.sender][claimedTokens[msg.sender][i]];
            
            delete userTokenBalances[msg.sender][claimedTokens[msg.sender][i]];
            
            __token.transfer(msg.sender, recievable);

            contractTokenBalances[claimedTokens[msg.sender][i]] = contractTokenBalances[claimedTokens[msg.sender][i]] - recievable;

            updateArray(claimedTokens[msg.sender][i]);

        }
        
        
        uint256 claimingPercent = initialStake[msg.sender] * 10000/stakeToken.balanceOf(address(this));
        uint claimmable = claimingPercent * feesTaken / 10000;

        stakeToken.transfer(msg.sender, claimmable);
        
        stakeToken.transfer(msg.sender, NormalBalance[msg.sender]);
        
        delete claimedWeek[msg.sender];
        delete NormalBalance[msg.sender];
        delete balances[msg.sender];
        delete Duration[msg.sender];
        activeStakers--;

        emit FinalizedStaking(msg.sender, claimmable);
     
    }
    
    function getBalance(address _token) external view returns(uint){
        IERC20Upgradeable token = IERC20Upgradeable(_token);

        return token.balanceOf(address(this));

    }

    function updateArray(address _token) public {
        
        if(IERC20Upgradeable(_token).balanceOf(address(this)) == 0){
            for(uint i = 1; i<= recievableTokens.length; i++){
                    if(recievableTokens[i-1] == _token){
                        recievableTokens[i-1] = recievableTokens[recievableTokens.length -1];

                        recievableTokens.pop();
                    }
            
                }

        }
    
    }

    function getPercent(address staker) external view returns(uint){
        uint256 claimingPercent = initialStake[staker] * 10000/stakeToken.balanceOf(address(this));
        return claimingPercent;
    }

    function getFeeBeingReceived() external view returns(uint){
        uint256 claimingPercent = initialStake[msg.sender] * 10000/stakeToken.balanceOf(address(this));
        uint claimmable = claimingPercent * feesTaken / 10000;
        return claimmable;
    }

    function getTokensEarned(address staker) external view returns(recievedTokens[] memory){
        return recievedTokensMapped[staker];
    }

    function getActiveStakingAmount(address staker) external view returns(uint){
        return balances[staker];
    }
    
    function getDurationLeft(address staker) external view returns(uint){
        return Duration[staker];
    }
    
    function getTotalStakedTokensInContract() external view returns(uint){
        return stakeToken.balanceOf(address(this));
    }

    function changePool(address newMotherPool) external{
        require(msg.sender == admin);
        MainPool = iMotherPool(newMotherPool);
    }
    
    function getTotalStakers() external view returns(uint){
        return activeStakers;
    }

}

