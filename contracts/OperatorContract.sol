// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@eth-optimism/contracts/libraries/standards/IL2StandardERC20.sol";
import "../contracts/Registry.sol";

contract OperatorContract is Ownable {
  using SafeMath for uint256;
  IL2StandardERC20 immutable bbsToken;
  Registry immutable registry;

  string public constant DWEB_OPERATOR_REG_ID = "dweb";
  uint256 public constant DWEB_PERCENTAGE = 10;
  uint256 public constant OPERATOR_PERCENTAGE = 10;

  struct ExchangeRequest {
    string user;
    uint256 amount;
    address bbsTo;
  }

  struct Community{
    string token_name;
    string owner;
    uint ownerPercentage;
    address ownerAddress;
    address cashier;
    mapping(uint256 => ExchangeRequest) cashierQ;
    uint256 nextQAdd;
    uint256 nextQExchange;
  }


  mapping(string => Community) public communities;
  // add  address _cashier
  event CommunityAdd (string _token_name, string _owner, uint8 _ownerPercentage, address ownerAddress);
  event CommunityTokensBuy (string _token_name, uint256 _amount, address _bbsPayingAdd, string _userRecivingTokens);
  event ExchangeRequestQueue (string _token_name, uint256 _amount, address _bbsTo, string _user);
  event test (string _a, uint256 _b);

  // Predeploy bbsL2 (optimism standard) contract & registry
  constructor(address _bbsL2, address _registry) {
    bbsToken = IL2StandardERC20(_bbsL2);
    registry = Registry(_registry);
    //console.log ("OperatorContract", _dWebOperatorContract);
  }

  function addComunity(string memory _token_name, string memory _owner,
    uint8 _ownerPercentage, address _ownerAddress, address _cashier) public  {
    //Check name uniquness, conract adress & auth_contract ligitimacy
    require(registry.users(_owner) == address(this), "User does not registered for this operator");
    registry.registerCommunity(address(this), _token_name);

    //communities[_token_name] = Community(_token_name, _owner, _ownerPercentage, _ownerAddress, _cashier);
    communities[_token_name].token_name = _token_name;
    communities[_token_name].owner = _owner;
    communities[_token_name].ownerPercentage = _ownerPercentage;
    communities[_token_name].ownerAddress = _ownerAddress;
    communities[_token_name].cashier = _cashier;

     emit CommunityAdd(_token_name, _owner, _ownerPercentage, _ownerAddress); //  _cashier
     console.log("_operator_id: ", address(this), " _token_name: ", _token_name);
     console.log(" _owner: ", _owner, "_ownerPercentage: ", _ownerPercentage);
     console.log(" _ownerAddress", _ownerAddress , " _cashier: ", _cashier);
  }

  function buyCommunityTokens(string memory _token_name, uint256 _amount,
  address _bbsPayingAdd, string memory _userRecivingTokens ) public  {
    //Check community & user belongs to this operator
    require(registry.users(_userRecivingTokens) == address(this), "User does not registered for this operator");
    require(communities[_token_name].cashier != address(0), "Token name does not exsist in this operator records ");

    // to dWeb (into dweb operator contract)
    uint256 reminingAmount = _amount;
    uint256 portion = SafeMath.div(SafeMath.mul(_amount, DWEB_PERCENTAGE), 100);
    bbsToken.transferFrom(_bbsPayingAdd, registry.operatorsNames(DWEB_OPERATOR_REG_ID), portion);
    reminingAmount = SafeMath.sub(reminingAmount, portion);

    // to the operator
    portion = SafeMath.div(SafeMath.mul(_amount, OPERATOR_PERCENTAGE), 100);
    bbsToken.transferFrom(_bbsPayingAdd, address(this), portion);
    reminingAmount = SafeMath.sub(reminingAmount, portion);

    // to the owner
    portion = SafeMath.div(SafeMath.mul(_amount, communities[_token_name].ownerPercentage), 100);
    bbsToken.transferFrom(_bbsPayingAdd, communities[_token_name].ownerAddress, portion);
    reminingAmount = SafeMath.sub(reminingAmount, portion);

    // the rst to the cashier
    bbsToken.transferFrom(_bbsPayingAdd, communities[_token_name].cashier, reminingAmount);

    emit CommunityTokensBuy ( _token_name, _amount, _bbsPayingAdd, _userRecivingTokens);
    console.log ("_token_name ", _token_name, " _amount:", _amount);
    console.log ("_bbsPayingAdd ", _bbsPayingAdd, " _userRecivingTokens:", _userRecivingTokens);
  }

  function transferRoylties(address _bbsFrom, address _bbsTo, uint256 _amount, uint256 _percentage) private returns(uint256) {
    uint256 portion = SafeMath.div(SafeMath.mul(_amount, _percentage), 100);
    bbsToken.transferFrom(_bbsFrom, _bbsTo, portion);
    return portion;
  }

  function queueExchangeRequest(string memory _token_name, uint256 _amount,
     address _bbsTo, string memory _user) public  {
    //Check name uniquness, conract adress & auth_contract ligitimacy
    require(communities[_token_name].cashier != address(0), "Token name does not exsist in this operator records. ");
    require(registry.users(_user) == address(this), "User does not registered for this operator");

    communities[_token_name].cashierQ[communities[_token_name].nextQAdd] =
     ExchangeRequest(_user, _amount, _bbsTo);
    communities[_token_name].nextQAdd += 1;

    emit ExchangeRequestQueue (_token_name, _amount, _bbsTo, _user);
    console.log ("ExchangeRequestQueue: _token_name ", _token_name, " _amount:", _amount);
    console.log ("_bbsTo: ", _bbsTo, " _usert:", _user);
  }

  function ExecuteQueueRequests(string memory _token_name) public returns(uint256)  {
    //Check name uniquness, conract adress & auth_contract ligitimacy
    require(communities[_token_name].cashier != address(0), "Token name does not exsist in this operator records. ");

    uint executed;
    uint allowance = bbsToken.allowance(communities[_token_name].cashier, address(this));

    for (uint256 i = communities[_token_name].nextQExchange;
       i < communities[_token_name].nextQAdd &&
       allowance >= communities[_token_name].cashierQ[i].amount ; i++) {

      bbsToken.transferFrom(communities[_token_name].cashier, communities[_token_name].cashierQ[i].bbsTo,
         communities[_token_name].cashierQ[i].amount);
      communities[_token_name].nextQExchange += 1;
      allowance = SafeMath.sub(allowance,communities[_token_name].cashierQ[i].amount);
      communities[_token_name].cashierQ[i] = ExchangeRequest('',0,address(0));
      executed += 1;

      console.log ("transferFrom ", communities[_token_name].cashier,
      communities[_token_name].cashierQ[i].bbsTo, communities[_token_name].cashierQ[i].amount);
    }

    return executed;
  }

  function invokEvent() public {
    emit test("This is a test print",999999);
  }

}
