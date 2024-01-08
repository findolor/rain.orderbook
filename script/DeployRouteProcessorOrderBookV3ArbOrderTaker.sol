// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Script} from "forge-std/Script.sol";
import {RouteProcessorOrderBookV3ArbOrderTaker} from "src/concrete/RouteProcessorOrderBookV3ArbOrderTaker.sol";
import {I9R_DEPLOYER} from "./DeployConstants.sol";

/// @title DeployRouteProcessorOrderBookV3ArbOrderTaker
/// @notice A script that deploys a `RouteProcessorOrderBookV3ArbOrderTaker`. This
/// is intended to be run on every commit by CI to a testnet such as mumbai, then
/// cross chain deployed to whatever mainnet is required, by users.
contract DeployRouteProcessorOrderBookV3ArbOrderTaker is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);
        RouteProcessorOrderBookV3ArbOrderTaker deployed = new RouteProcessorOrderBookV3ArbOrderTaker(I9R_DEPLOYER);
        (deployed);
        vm.stopBroadcast();
    }
}
