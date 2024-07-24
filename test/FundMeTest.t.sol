// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  address ALICE = makeAddr("Alice");
  uint256 constant SEND_ETHER = 0.1 ether;
  uint256 constant STARTING_BALANCE = 1 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    // us->fundmetest->fundme
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(ALICE, STARTING_BALANCE); // will send balance to alice
  }

  function testMinimumDollarIsFive() public {
    uint256 expectedValue = 5 * 10 ** 18;
    uint256 actualValue = fundMe.MINIMUM_USD();
    assertEq(actualValue, expectedValue);
  }

  function testOwnerIsMsgSender() public {
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function testPriceFeedVersionIsAccurate() public {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  } 

  function testFundFailWithoutEnoughEth() public {
    vm.expectRevert();
    fundMe.fund();
  }

  function testFundUpdatesFundedDataStructrue() public {
    vm.prank(ALICE); // next tx will send by alice
    fundMe.fund{value: SEND_ETHER}();
    assertEq(fundMe.getAddressToAmounts(ALICE), SEND_ETHER);
  }

  function testAddFunderToArrayOfFunders() public {
    vm.prank(ALICE); // next tx will send by alice
    fundMe.fund{value: SEND_ETHER}();

    address funder = fundMe.getFunders(0);
    assertEq(funder, ALICE);
  }

  modifier funded {
    vm.prank(ALICE); // next tx will send by alice
    fundMe.fund{value: SEND_ETHER}();
    _;
  }

  function testOnlyOwnerCanWithdraw() public funded{
    vm.prank(ALICE);
    vm.expectRevert();
    fundMe.withdraw();
  }

  function testCanWithdrawWithSingleFunder() public funded {
    uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // uint256 gasStart = gasleft();
    // vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();
    // uint256 gasEnd = gasleft();
    // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    // console.log(gasUsed);

    uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;

    assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingFundMeBalance);
    assertEq(endingFundMeBalance, 0);
  }

  function testCanWithdrawWithMultipleFunders() public funded {
      uint160 numberOfFunfers = 10;
      uint160 startingFunderIndex = 1;

      for (uint160 i = startingFunderIndex; i < numberOfFunfers; i++) {
        hoax(address(i), SEND_ETHER); // vm.prank + vm.deal both in one function
        fundMe.fund{value: SEND_ETHER}();
      }

      uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
      uint256 startingFundMeBalance = address(fundMe).balance;

      vm.prank(fundMe.getOwner());
      fundMe.withdraw();

      uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
      uint256 endingFundMeBalance = address(fundMe).balance;

      assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingFundMeBalance);
      assertEq(endingFundMeBalance, 0);
  }

  function testCanWithdrawWithMultipleFundersCheaper() public funded {
      uint160 numberOfFunfers = 10;
      uint160 startingFunderIndex = 1;

      for (uint160 i = startingFunderIndex; i < numberOfFunfers; i++) {
        hoax(address(i), SEND_ETHER); // vm.prank + vm.deal both in one function
        fundMe.fund{value: SEND_ETHER}();
      }

      uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
      uint256 startingFundMeBalance = address(fundMe).balance;

      vm.prank(fundMe.getOwner());
      fundMe.cheaperWithdraw();

      uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
      uint256 endingFundMeBalance = address(fundMe).balance;

      assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingFundMeBalance);
      assertEq(endingFundMeBalance, 0);
  }

}


// # forge test -vvv --fork-url $RPC_URL
// # forge snapshot // for gas tracking
// forge inspect FundMe storageLayout // to see the storage layout