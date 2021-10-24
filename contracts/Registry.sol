// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Registry is Ownable {

  struct operator{
    address id_contract;
    string name;
    address auth_contract;
  }
  mapping(string => address) public operatorsNames;
  mapping(address => operator) public operators;
  event OperatorRegister(address _id_contract, string _name, address _uthContract);

  // community is deffined by Token name & holds its operator contract
  mapping(string => address) public communities;
  event CommunityRegister(address _operator_contract, string _name);

  // User is deffined by name & holds its operator contract (insted of domain)
  mapping(string => address) public users;
  event UserRegister(address _operator_contract, string _name);


  // First operator after deploying registery should be registering dWeb OperatorRegister
  // This cannot be done in the constructor becouse OperatorContract should get the reg address
  // on its deployment

  function registerDweb(address _id_contract) public onlyOwner {
     operators[_id_contract] = (operator(_id_contract, "dweb", _id_contract));
     operatorsNames["dweb"] = _id_contract;

     emit OperatorRegister(_id_contract, "dweb", _id_contract);
     console.log ("Operator dweb, contract id:", _id_contract);
  }

  function registerOperator(address _id_contract, string memory _name, address _authContract) public  {
    //Check name uniquness, conract adress & auth_contract ligitimacy
    require(operatorsNames[_name] == address(0), "Operator with this name already exists");
    require(operators[_authContract].id_contract != address(0),
    "_authContract is not registered");

     operators[_id_contract] = (operator(_id_contract, _name, _authContract));
     operatorsNames[_name] = _id_contract;

     emit OperatorRegister(_id_contract, _name, _authContract);
     //console.log ("Operator ", _name, " contract id:", _id_contract);
  }

  function registerCommunity(address _operator_contract, string memory _name) public  {
    //Check name uniquness, conract adress ligitimacy
    require(communities[_name] == address(0) , "Community with this name already exists");
    require(operators[_operator_contract].id_contract != address(0),
    "_operator_contract is not registered");

     communities[_name] = _operator_contract;

     emit CommunityRegister(_operator_contract, _name);
     console.log ("Community ", _name, " operator contract id:", _operator_contract);
  }

  function registerUser(address _operator_contract, string memory _name) public  {
    //Check name uniquness, conract adress ligitimacy
    require(users[_name] == address(0) , "User with this name already exists");
    require(operators[_operator_contract].id_contract != address(0),
    "_operator_contract is not registered");

     users[_name] = _operator_contract;

     emit UserRegister(_operator_contract, _name);
     //console.log ("User ", _name, " operator contract id:", _operator_contract);
  }

}
