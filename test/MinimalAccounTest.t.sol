// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;

    function setUp() public {
        DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimalAccount
            .deployMinimalAccount();
    }
}
