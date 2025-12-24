//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712("MerkleAirdrop", "1.0.0") {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidMerkleProof();
    error MerkleAirdrop__InvalidMerkleProofSignature();

    struct Airdrop {
        address account;
        uint256 amount;
    }

    event Claim(address indexed account, uint256 amount);

    mapping(address claimer => bool claimed) private s_hasClaimed;
    address[] public claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_token;

    constructor(bytes32 _merkleRoot, IERC20 _token) {
        i_merkleRoot = _merkleRoot;
        i_token = _token;
    }

    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        if (!_isValidSignature(_account, getMessage(_account, _amount), v, r, s)) {
            revert MerkleAirdrop__InvalidMerkleProofSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }
        s_hasClaimed[_account] = true;
        emit Claim(_account, _amount);

        i_token.safeTransfer(_account, _amount);
    }

    function _isValidSignature(address _account, bytes32 _message, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(_message, v, r, s);
        return signer == _account;
    }

    function getMessage(address _account, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Airdrop(address account,uint256 amount)"), Airdrop({account: _account, amount: _amount})
                )
            )
        );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_token;
    }
}
