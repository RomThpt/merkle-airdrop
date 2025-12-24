// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract ClaimAirdrop is Script {
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32[] public PROOF = [
        bytes32(0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad),
        bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
    ];
    error Interact__InvalidSignatureLength();

    bytes private signature =
        hex"215d959b8b505d692bb0c288ba717ec8c4bb1a4b4e884d9a4c54a73ac456cd5e0a90bf295c9eadcfa36635964044a08506ee78706c84bf26346c54dcd7363da31c";

    // Signature components (v, r, s) - these would be generated off-chain
    uint8 v;
    bytes32 r;
    bytes32 s;

    function _claimAirdrop(address _airdropAddress) internal {
        vm.startBroadcast();
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(signature, (uint8, bytes32, bytes32));
        MerkleAirdrop(_airdropAddress).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, _v, _r, _s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert Interact__InvalidSignatureLength();
        }

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        _claimAirdrop(mostRecentlyDeployed);
    }
}
