//SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant ETH_AMOUNT = 0.05 ether; //300000000000000000
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 30 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFifty() public {
        assertEq(fundMe.MINIMUM_USD(), 50e18);
    }

    function testOwnerIsmessageSender() public {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        assertEq(fundMe.getOwnerAddress(), msg.sender);
    }

    function testPriceFeedVersionIsAccurrate() public {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testRevertWhenEthIsNotEnough() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testDataFundStructure() public {
        vm.prank(USER); //the Tx will be sent by USER
        fundMe.fund{value: ETH_AMOUNT}();
        uint256 amountFunded = fundMe.getAddressToAmount(USER);
        assertEq(amountFunded, ETH_AMOUNT);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); //the Tx will be sent by USER
        fundMe.fund{value: ETH_AMOUNT}();
        address funderAddress = fundMe.getFunders(0);
        assertEq(funderAddress, USER);
    }

    modifier funded() {
        vm.prank(USER); //the Tx will be sent by USER
        fundMe.fund{value: ETH_AMOUNT}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); //the Tx will be sent by USER
        vm.expectRevert();
        fundMe.Withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 startGas = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwnerAddress());
        fundMe.Withdraw(); //Should have spent some gas

        // uint256 endGas = gasleft();
        // uint256 gasUsed = (startGas - endGas) * tx.gasprice;
        // console.log(gasUsed);
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwnerAddress().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawWithMultiFunders() public funded {
        //Arrange
        uint160 number = 10;
        uint160 startingIndex = 1;
        for (uint160 index = startingIndex; index <= number; index++) {
            //vm.prank --> create new address
            //vm.deal --> fund the new created
            //address(0) 0r address(1)---> the number must uint160
            hoax(address(index), ETH_AMOUNT);
            fundMe.fund{value: ETH_AMOUNT}();
            // address fundersAddresses = fundMe.getFunders(index);
        }

        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwnerAddress());
        fundMe.Withdraw(); //Should have spent some gas
        vm.stopPrank();
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwnerAddress().balance;
        assert(endingFundMeBalance == 0);
        assert(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawWithMultiFundersCheaper() public funded {
        //Arrange
        uint160 number = 10;
        uint160 startingIndex = 1;
        for (uint160 index = startingIndex; index <= number; index++) {
            //vm.prank --> create new address
            //vm.deal --> fund the new created
            //address(0) 0r address(1)---> the number must uint160
            hoax(address(index), ETH_AMOUNT);
            fundMe.fund{value: ETH_AMOUNT}();
            // address fundersAddresses = fundMe.getFunders(index);
        }

        uint256 startingOwnerBalance = fundMe.getOwnerAddress().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwnerAddress());
        fundMe.cheaperWithdraw(); //Should have spent some gas
        vm.stopPrank();
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwnerAddress().balance;
        assert(endingFundMeBalance == 0);
        assert(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance
        );
    }
}
