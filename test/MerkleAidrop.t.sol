//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public bagelToken;

    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32[] public PROOF = [
        bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
        bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
    ];
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;

    address user;
    uint256 userPrivKey;

    function setUp() public {
        bagelToken = new BagelToken();
        airdrop = new MerkleAirdrop(MERKLE_ROOT, bagelToken);
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_CLAIM * 4);
        bagelToken.transfer(address(airdrop), AMOUNT_TO_CLAIM * 4);

        (user, userPrivKey) = makeAddrAndKey("user");
    }

    function testUsersCanClaim() public {
        uint256 initalBalance = bagelToken.balanceOf(user);

        vm.prank(user);
        vm.deal(user, 1 ether);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);

        uint256 finalBalance = bagelToken.balanceOf(user);
        assertEq(finalBalance - initalBalance, AMOUNT_TO_CLAIM);
    }
}
