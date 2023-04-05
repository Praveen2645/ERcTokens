//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19; 

interface ERC20Interface { function totalSupply() external view returns (uint);
function balanceOf(address tokenOwner) external view returns (uint balance); 
function transfer(address to, uint tokens) external returns (bool success);
function allowance(address tokenOwner, address spender) external view returns (uint remaining);
function approve(address spender, uint tokens) external returns (bool success);
function transferFrom(address from, address to, uint tokens) external returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
//inheriting the  ERC20 interface
contract Block is ERC20Interface{ 
    string public name="Block";//name of the token string public symbol ="BLK";

string public decimal="0";
uint public override totalSupply;
address public founder;
mapping(address=>uint) public balances;
mapping(address=>mapping(address=>uint)) allowed;

constructor(){
    totalSupply=100000; // total supply of the token
    founder=msg.sender; // founder or the deployer of the contract
    balances[founder]=totalSupply; //balance of the founder set to total supply as tokent arent distributed yet
}
// from ERC20Interface
// function to know the balance of the particular token owner
function balanceOf(address tokenOwner) public view override returns(uint balance){
    return balances[tokenOwner];
}
// from ERC20Interface
// function to transfer the token to an address
function transfer(address to,uint tokens) public override virtual returns(bool success){
    require(balances[msg.sender]>=tokens); // checking msg.sender(one who transfering) have enough tokens
    balances[to]+=tokens; //balances[to]=balances[to]+tokens; // transfering or adding tokens to (to address)
    balances[msg.sender]-=tokens;// deducting tokens from the msg.sender
    emit Transfer(msg.sender,to,tokens);
    return true;
}
// function to approve the spender, the tokens
function approve(address spender,uint tokens) public override returns(bool success){
    require(balances[msg.sender]>=tokens);//check the balance of owner, whether he have enough tokens or not
    require(tokens>0);// tokens must be greater than zero
    allowed[msg.sender][spender]=tokens; // nested mapping ,that msg.sender has allowed the spender the amount of tokens
    emit Approval(msg.sender,spender,tokens);
    return true;
}
// function to return the number of tokens, the token owner has approved to the spender
function allowance(address tokenOwner,address spender) public view override returns(uint noOfTokens){
    return allowed[tokenOwner][spender];
}
// function to transfer tokens to an address
function transferFrom(address from,address to,uint tokens) public override virtual returns(bool success){
    require(allowed[from][to]>=tokens);//checking whethever approval for token is given or not
    require(balances[from]>=tokens);
    balances[from]-=tokens;// decresing the token balance of(from)
    balances[to]+=tokens;// increasing the token balance of (to)
    return true;
}
}
//inheritng the Block contract
contract ICO is Block{

address public manager;
address payable public deposit; //investors will deposite the ethers

uint tokenPrice=0.1 ether; // token price of one token

uint public cap=300 ether; //total tokens for circulation in ICO 

uint public raisedAmount; // amount raised for an ICO

uint public icoStart=block.timestamp;// at the time of deployment our ICO will start
uint public icoEnd=block.timestamp+3600; //1 hour=60*60 seconds; //ICO will run for an hour

uint public tokenTradeTime=icoEnd+3600;
//max and min investment made by a investor to buy a token
uint public maxInvest=10 ether;
uint public minInvest=0.1 ether;

//State of an ICO of enum type
enum State{beforeStart,afterEnd,running ,halted}

State public icoState; 

event Invest(address investor,uint value,uint tokens);

constructor(address payable _deposit){
    deposit=_deposit;
    manager=msg.sender;
    icoState=State.beforeStart;
}

modifier onlyManager(){
    require(msg.sender==manager); // for only manager
    _;
}

function halt() public onlyManager{ // function to halt the ICO only by manager
    icoState=State.halted;
}
function resume() public onlyManager{//function to resume the ICO only by manager
    icoState=State.running;
}
function changeDepositAddr(address payable newDeposit) public onlyManager{// this function can change the deposite address in case of an emergency
    deposit=newDeposit;
}
function getState() public view returns(State){ // this function is for getting the State of the ICO
    if(icoState==State.halted){
        return State.halted;
    }else if(block.timestamp<icoStart){
        return State.beforeStart;
    }else if(block.timestamp>=icoStart && block.timestamp<=icoEnd){
        return  State.running;
    }else{
        return State.afterEnd;
    }
}

function invest() payable public returns(bool){ // function invest() for investor, can invest ether and get the tokens
    icoState=getState();//finding the state of the ICO when investor is investing
    require(icoState==State.running,"ICO is not running"); // ICO state should be running while investing
    require(msg.value >=minInvest && msg.value <=maxInvest); //checking the condition for msg.value
    
    raisedAmount+=msg.value; // raised the amount send by the investors to the contract
    
    require(raisedAmount<=cap);//raised amount should not be greater than or equal to the cap amount
    
    uint tokens=msg.value/tokenPrice;  //suppose investor send the 10 eth, and token price is 0.1 i.e 10/0.1=100 therefore the investor will get 100 tokens;
    balances[msg.sender]+=tokens; // increasing the token balance of the investor 
    balances[founder]-=tokens;// decreasing the token balance off the investor
    deposit.transfer(msg.value); // transfering value to the deposite address.
    
    emit Invest(msg.sender,msg.value,tokens);// emit the event
    return true;
}
// function to burn the number of tokens
function burn() public  onlyManager returns(bool){
    icoState=getState();
    require(icoState==State.afterEnd,"the ICO is running wait to end it"); //to burn the tokens the state of the ICO should end
    balances[founder]=0;// after burn token balance will be zero 
    return true;
}
//function from block contract
function transfer(address to,uint tokens) public override returns(bool success){
    require(block.timestamp>tokenTradeTime);// allowing investor to transfer tokens only when the trade time has begun
    super.transfer(to,tokens);// "super" make sure that the transfer function is from the parent contract that is "Block". incase we not write super, it will call the transfer () that is itself. we can also use "Block",but in OOPS we use super
    return true;
}
//function is from block contract to transfer the token
function transferFrom(address from,address to,uint tokens) public override returns(bool success){
    require(block.timestamp>tokenTradeTime,"Token trade time ended");
    Block.transferFrom(from,to,tokens); //here we use "Block" instead of super
    return true;
}

receive() external payable{ // it is basically receive ethers, from the invest() or through copying address directly, the one who call the function direclty from the metamask this receive function will help to call the invest()
    invest();
}
}
