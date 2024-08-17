// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Chainrity} from "src/Chainrity.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployChainrity is Script {
    //   function setUp() public {}

    function run() public returns (Chainrity) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        Chainrity chainrity = new Chainrity(ethUsdPriceFeed);
        vm.stopBroadcast();
        return chainrity;

        //       console.log("Chainrity contract address: ", chainrity);
    }
}
