// creat raffle contract 
//enter the lottery (paying some amount ) 
// pick a random winner(verifiably random )
//winner to be selected every x minutes  ( we want this is compeletly automated  so we want to deploy the smart contract and almost have no maintenance almost have nobaody ever have to touch it again and it will just automatically run forever this is the power of smart contract )

// we are going to need  to use a chainlink oracle since we are going to need to get the randomness from outside the  blockchain and we are going to need to have that automated  excution  
// beacuse a smart contract can excute itself 













//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";




  




error Raffle_NotEnoughETHEntered();
error Raffle_TransferFailed();
error RAffle_NotOpen();
error Raffle_UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);







/*******
 * @title a sample raffle contract 
 * @author nitish kumar 
 * @notice this contract is for creating an untraperable decentralized smart contract 
 * @dev  this implement chainlink vrf  v2  and chainlink  keepers 
 */














// be have a chainlink vrfconsumerbase contract
// and we are going to need to make our raffle vrf consumer  base 
// we  are goona need to inherit vrf consumer base 
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {



/* Type declaration */
enum RaffleState{
    OPEN,
    CALCULATING
}// uint256 0= open,  1= calculating
















// in the past  we created project like fund me where people can send ether to  our contracts or send whatever native blockchain token to our  smart contract  using the msg.dot value  based off  of some usd value 
// for this one  we are just going to have the  entrance fee insted be usd based  it just going to be that native asset 
// so for our enter Raffle we do not have to  set a usd price 
// we can just set a minimum eth price 
 
 // we now that this entrance fee  is going to be storage variable 
 // make it private varibale  bcz we always want  to set our visibility but lets have the entrance fee be configurable 
 //well if we are goona only set entrancefee one time  we migt as  well make this a constant or an immutable variable  so  that we  save some gas  we will change from S to i









 /* state Variable */
    uint256  private immutable  i_entranceFee;
//now that we know they are calling into raffle with enough value 
    //ae are  probably going to want to keep track of all the users who  actually  enter our raffle 
    // that way when we pick a winner  we know whos in the running 
    // so lets creat an array of players 
    // of course players is going to storage variable because we are going to modify this a lot  we are going to be adding and substracting players all the  time 
    // so we are going to do  s players and make this private as well and we are going to makes this address payable players because one of these players wins  we are going to need to  have to pay them 
    // so we will make this address payable private as  player
    address payable[] private s_players;
// our vrf coordinator is indeed an immutable variable
// creat a variable name vrfCoordinator with type VRFCoordinatorV2Interface 
    VRFCoordinatorV2Interface private immutable  i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;











    // lootery Variables 
    address private s_recentWinner;
    RaffleState private s_raffleState;
    
    uint256 private  s_lastTimeStamp;
    uint256 private immutable i_interval;
    



















    /* EVENTS */



    // EVENT 
      // WHen ever we update  a  dynamic object like array or mapping we always want to omit a event   
        

        // evm etherum virtual machine and evm have a functionality called logging functionality 
        // then things happen on a blockchain the evm writes these  thing to a specific data structure called its log 
        // we can  actullay read these log from our blockchain nodes that we run  in fact if you run a nnode or you connect to a node you can make a eth_getlog 
        // now inside these logs is an importaNT  piece of logging calledd event 
        // and this  is the main piece that we are goona be talking about 
        //event allow you to print information to this logging  structure in a way that more gas efficient than actually saving it to something like a storage variable 
        // these events  and logs live in this special data structure  that is not accessible to smart contract 
        // that why its cheaper bcz smart contract can accees thenm so that if the trade off here  we can still print some information  that important  to  us without having to save it in a storage variable  which is  going to take up much more gas  
        // each one  of these  event is  try to the smart contract or account address that emiitted this event  in these  transaction 
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    //and now that we have  picked a winner right now we do not have a way to actually  keep track of the list of previous winners 
    // so we are just  going to omit an event  so there alaways going to be that easily query double history of event winners so we are going to  creat a new event 
    event WinnerPicked(address indexed winner);
    















    
    // let creat a constructor and we will have this entrancefee be settable in our constructor


    // after importing chainlink vrf contract 

    // now if we llok in our docs in our constructor  we need to pass  thr VRF consumerbase v2 constructor and pass vrf coordinator 
    // agin this vrf  coordinator is the address of the  contract that does the random  number verfication  
    constructor(address vrfcoordinatorV2 ,uint256 entranceFee,bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit,uint256 interval) VRFConsumerBaseV2(vrfcoordinatorV2){
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfcoordinatorV2);
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        // block.timestamp return  the current timestamp of the blockchain  
        s_lastTimeStamp =  block.timestamp;
        i_interval = interval; 
    }


















   

//function enter raffle 


// we definitely want our enterraffle to be public and to be payable  since we are having people send message dot value and we want anyone to be able to enter our raffle 
    function enterFaffle() public payable {
        //require (msg.value < i_entranceFee,"not enough ETh")
        // what we have learned before about those  error codes, so we could use require mesaage dot value , or we  could do one of these custom error which is going to be a lot more gas efficent ,beacuse insted of sorting this string we are just going to store an error code in our smart contract 
        // so lets do that , insted 

        //if the user does not send enough value will revert with notenoughethentered 
        if(msg.value < i_entranceFee){revert Raffle_NotEnoughETHEntered();}
        
        if (s_raffleState != RaffleState.OPEN){
            revert RAffle_NotOpen();
        }



        // we know that palyers is going to be storage variable and we are going to add it our enter raffle 
        //now we have a aaray and someones entered the raffele we will do 
        // now this actually does not work beacuse message dot sender ic not a payable address so we will need  to typecast it as a payable address 
        //so now we have a way to keep track of all the players that are entering a raffle 
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }



















/*
@dev this is the function that  the chainlink keeper nodes call 
they look for the  upkeepneeded to  return  true 
following should be true  in order  to  return  true 
 1 our time interval  should have passed 
 2 the lottery should  have  at  least one player  and have some eth 
 4 then  our subscription  is  funded  with link 
  5 the lotter should be open  state 
*/


// now this check upkeep bytes call data allows us  to specify really anything that we want when we call this checupkeep  function 
// having this check data be of type bytes  means that we can even specify this to call other function 
function checkUpkeep(bytes memory /*checkData*/) public override returns (bool upkeepNeeded,bytes memory /*performData */ ){
    bool isOpen = (RaffleState.OPEN == s_raffleState);
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval );
    bool  hasPlayers = (s_players.length > 0);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded =(isOpen &&  timePassed && hasPlayers && hasBalance);
} 




















// so we are going to creat our function here called  pick random winner this function is going to be called  by the chain link keepers  network  so that this can automatically run without us having to intrect with it  
// and  now our pick  random winner function we are actually not going to make  public  we are going  to make external 
//extrnal function are a little bit cheaper than public function because solidity knows that our own contract can call this 


    function performUpkeep(bytes calldata /* performDATA */) external override {
        (bool  upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle_UpkeepNotNeeded(address(this).balance, s_players.length,uint256(s_raffleState));
        }
        
        // now additionally  update the sate to be calculating so other  people  can not jump in here 
        s_raffleState = RaffleState.CALCULATING;
        // in order to pick a random winner we actually have to do two things 
        // 1   we first have to request the random number 
        // and the  once we get it  do something with it 
        //so chainlinkvrf is a two  transaction process  and this is actually intentional 
        // Will revert if subscription is not set and funded. define who  is requesting this and all this information 
        //this request random words function return a  request id  a uint 256 request id  a unique id that
        uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane,// the gas lane key hash value which is the maximum gas price you are willing to pay for a request in wei. it is function as an id of the offchain vrf  job that runs in response to request 
            i_subscriptionId,// subscriptionid that this contract uses for funding requests
            REQUEST_CONFIRMATIONS ,// requestconfimation is a uint16  which says how many confirmation the  chainlink node should wait before responding 
            //so make a request , and there is only one block confirmation maybe  you dont actually send it because you dont you are afraid  of some type  of blockchain reorganization  or something 
          i_callbackGasLimit, // call back gas limit  for  how  much gas  to use for the callback  request to your contract fulfillrandomwords  function ,, it must be less than the maxgaslimit  limit on the coordinator contract 
            NUM_WORDS // numwords this is going to be how many random  numbers that we want to get , we only want one 
        );
        emit RequestedRaffleWinner(requestId);
        // and now we have a function that we can use to request a random winner using chainlink vrf 
    }


// now again set up so that the chainlink keepers call this on an interval  





















// and this function the random number is going  to be returned and in the transaction that we actually get  the random number from the chain link network that we are  going to actually send the money to the winner 

// and we  go to the chainlink documentation the function that the cahinlink  node calls is the function called fulfill random words 
// noe fulfiil random word  basically mean we are fulfullinig random number the word come  from computer science terminolog  but you can  basicaally just think of this as fulfill random numbers bcz be get multiple random numbers 

// this is what i am expecting  us to  
// i am expecting the override the fullfill random word which take these parameters 

// once we get that random number we are going to want to pick a random winner from our array of players  up 
    function fulfillRandomWords( uint256  /*requestId*/,uint256[] memory randomWords) internal override {
        uint256 indexofWinner = randomWords[0] % s_players.length;
        address payable  recentWinner = s_players[ indexofWinner];
        //so now we will have the address of the person that got this random number the person thats going to be our verifiably random winner.
        s_recentWinner = recentWinner;
        s_raffleState= RaffleState.OPEN;
        // after we pick a winner from s player we need to  reset our players array  so lets add that 
        s_players =  new address payable[](0); 
      // every time a winner is  picked we want to reset the timestamp as well so that we can  wait another interval and let people participate in the  lottery for that interval 
      s_lastTimeStamp =  block.timestamp;

        // so now that we have a recent winner  what else are we goona do?
        // well we are probably going to  want to send them the money in this contract 
        (bool success, ) =recentWinner.call{value: address(this).balance}("");
        // require (success )
        if(!success){
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

























/**
 * view and pure function 
 */



//  now we have a function that users can call to get the entrancefee 
    function getEntranceFee() public  view  returns(uint256){
        return i_entranceFee;
    }
// since we are going to make players private and its probably good that we know whos in the players array we will even  do function it player that will be a public view
     function getplayer(uint256 index) public view  returns(address){
        return s_players[index];
     } 
    

    //we will probably want people to know who  this is winner 
    function getRecentWinner() public  view  returns (address){
        return s_recentWinner;
    } 
// we probably want to  give people the chance to get a rafflestate 
     function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
//we probably want to give people the chance to get the number of  words 
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

     function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

     function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }



}