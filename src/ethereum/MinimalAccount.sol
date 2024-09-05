// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from  "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";


contract MinimalAccount is IAccount, Ownable  {
    error MinimalAccount__NotFromEntryPoint();
    error  MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes result);

    IEntryPoint private immutable i_entryPoint;

    modifier requireFromEntryPoint(){
        if(msg.sender != address(i_entryPoint)){
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner(){
        if( msg.sender != address(i_entryPoint) && msg.sender != owner()){
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }


    constructor(address entryPoint)Ownable(msg.sender){
        i_entryPoint = IEntryPoint(entryPoint);
    }

    //A signature is valid if it is thecontract owner's address
    function validateUserOp(PackedUserOperation calldata userOp ,bytes32 userOpHash, uint256 missingAccountFunds )external returns (uint256 validationData) {
       validationData =    _validateSignature(userOp, userOpHash);
       _payPrefund(missingAccountFunds);
    }

    receive() external payable {
        
    }

    function execute(address dest, uint256 value, bytes calldata functionData)external  requireFromEntryPoint() {
            (bool success, bytes memory result) = dest.call{value: value}(functionData);
            if(!success){
                revert MinimalAccount__CallFailed(result);
            }
    }


    // EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns(uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if(signer != owner()){
            return SIG_VALIDATION_FAILED;
        }else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal  {
        if(missingAccountFunds != 0){
            (bool success,) = payable (msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        } 
    }



    function getEntryPoint() external view returns(address) {
        return address(i_entryPoint);
    }
}