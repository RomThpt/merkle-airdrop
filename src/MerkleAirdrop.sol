//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidMerkleProof();

    event Claim(address indexed account, uint256 amount);

    mapping(address claimer => bool claimed) private s_hasClaimed;
    address[] public claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_token;

    constructor(bytes32 _merkleRoot, IERC20 _token) {
        i_merkleRoot = _merkleRoot;
        i_token = _token;
    }

    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (s_hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }
        s_hasClaimed[_account] = true;
        emit Claim(_account, _amount);

        i_token.safeTransfer(_account, _amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_token;
    }
}
