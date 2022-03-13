// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 0.001 ether;
  uint256 deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw = false;
  bool public called = false;

  event Stake(address _staker, uint256 _amount);
  event Received(address _from, uint256 _amount);  

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier timePassed() {
    require(block.timestamp >= deadline,'at least 30 sec must have passed');
    _;
  }

  modifier callOnce() {
    require(called == false, 'you can execute only once');
    _;
  }

  modifier notCompleted() {
    require(isCompleted() == false, 'contract has already executed');
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public timePassed callOnce notCompleted{
    if(address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
    else {
      openForWithdraw = true;
    }
    called = true;
   }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable) public notCompleted {
    require(openForWithdraw == true, 'withdrawals not open yet');
    uint256 balance = balances[msg.sender];
    require(balance > 0, 'you do not have anything staked');
    balances[msg.sender] = 0;
    msg.sender.call{value: balance}("");
  } 

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() external view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  function isCompleted() public returns (bool) {
    return exampleExternalContract.completed();
    }

  // Add the `receive()receive() external payable {
   receive() external payable {
   emit Stake(msg.sender, msg.value);
   emit Received(msg.sender, msg.value);
  }

}
