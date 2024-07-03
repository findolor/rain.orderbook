// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {OrderBookExternalRealTest} from "test/util/abstract/OrderBookExternalRealTest.sol";
import {
    OrderConfigV3,
    EvaluableV3,
    OrderV3,
    ActionV1,
    SignedContextV1
} from "rain.orderbook.interface/interface/unstable/IOrderBookV4.sol";
import {LibTestAddOrder} from "test/util/lib/LibTestAddOrder.sol";
import {LibOrder} from "src/lib/LibOrder.sol";

contract OrderBookRemoveOrderEnactTest is OrderBookExternalRealTest {
    using LibOrder for OrderV3;

    function checkReentrancyRW(uint256 expectedReads, uint256 expectedWrites) internal {
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(iOrderbook));
        // 3 reads for reentrancy guard.
        // 1 reads for remove order.
        assert(reads.length == expectedReads);
        assert(reads[0] == bytes32(uint256(0)));
        assert(reads[1] == bytes32(uint256(0)));
        assert(reads[reads.length - 1] == bytes32(uint256(0)));
        // 2 writes for reentrancy guard.
        // 1 write for remove order.
        assert(writes.length == expectedWrites);
        assert(writes[0] == bytes32(uint256(0)));
        assert(writes[writes.length - 1] == bytes32(uint256(0)));
    }

    function checkRemoveOrder(
        address owner,
        OrderConfigV3 memory config,
        bytes[] memory evalStrings,
        uint256 expectedReads,
        uint256 expectedWrites,
        bool addOrder
    ) internal {
        LibTestAddOrder.conformConfig(config, iInterpreter, iStore);
        vm.startPrank(owner);
        ActionV1[] memory actions = new ActionV1[](evalStrings.length);
        for (uint256 i = 0; i < evalStrings.length; i++) {
            actions[i] =
                ActionV1(EvaluableV3(iInterpreter, iStore, iParserV2.parse2(evalStrings[i])), new SignedContextV1[](0));
        }
        // Hacky way to give a unique nonce to each order passed in.
        config.nonce = keccak256(abi.encode(evalStrings));
        if (addOrder) {
            iOrderbook.addOrder2(config, new ActionV1[](0));
        }
        OrderV3 memory order = OrderV3(owner, config.evaluable, config.validInputs, config.validOutputs, config.nonce);
        vm.record();
        bool stateChanged = iOrderbook.removeOrder2(order, actions);
        assertEq(stateChanged, addOrder);
        checkReentrancyRW(addOrder ? 5 : 4, addOrder ? 3 : 2);
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(iStore));
        assert(reads.length == expectedReads);
        assert(writes.length == expectedWrites);
        vm.stopPrank();
    }

    function testRemoveOrderEmptyNoop(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals = new bytes[](0);
        checkRemoveOrder(alice, config, evals, 0, 0, true);
    }

    function testRemoveOrderOneStateless(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals = new bytes[](1);
        evals[0] = bytes("_:1;");
        checkRemoveOrder(alice, config, evals, 0, 0, true);
    }

    function testRemoveOrderOneReadState(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals = new bytes[](1);
        evals[0] = bytes("_:get(0);");
        checkRemoveOrder(alice, config, evals, 2, 1, true);
    }

    function testRemoveOrderWriteStateSingle(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals0 = new bytes[](1);
        evals0[0] = bytes(":set(1 2);");
        checkRemoveOrder(alice, config, evals0, 1, 1, true);

        bytes[] memory evals1 = new bytes[](1);
        evals1[0] = bytes(":ensure(equal-to(get(1) 2) \"set works\");");
        checkRemoveOrder(alice, config, evals1, 2, 1, true);
    }

    function testRemoveOrderWriteStateSequential(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals0 = new bytes[](4);
        evals0[0] = bytes(":set(1 2);");
        evals0[1] = bytes(":ensure(equal-to(get(1) 2) \"0th set not equal\");");
        evals0[2] = bytes(":set(2 3);");
        evals0[3] = bytes(":ensure(equal-to(get(2) 3) \"1st set not equal\");");
        checkRemoveOrder(alice, config, evals0, 6, 4, true);
    }

    function testRemoveOrderWriteStateDifferentOwnersNamespaced(address alice, address bob, OrderConfigV3 memory config)
        external
    {
        vm.assume(alice != bob);
        bytes[] memory evals0 = new bytes[](4);
        evals0[0] = bytes(":set(1 2);");
        evals0[1] = bytes(":ensure(equal-to(get(1) 2) \"0th set not equal\");");
        evals0[2] = bytes(":set(2 3);");
        evals0[3] = bytes(":ensure(equal-to(get(2) 3) \"1st set not equal\");");
        checkRemoveOrder(alice, config, evals0, 6, 4, true);

        bytes[] memory evals1 = new bytes[](4);
        evals1[0] = bytes(":set(1 20);");
        evals1[1] = bytes(":ensure(equal-to(get(1) 20) \"0th set not equal\");");
        evals1[2] = bytes(":set(2 30);");
        evals1[3] = bytes(":ensure(equal-to(get(2) 30) \"1st set not equal\");");
        checkRemoveOrder(bob, config, evals1, 6, 4, true);

        bytes[] memory evals2 = new bytes[](2);
        evals2[0] = bytes(":ensure(equal-to(get(1) 2) \"alice state 1\");");
        evals2[1] = bytes(":ensure(equal-to(get(2) 3) \"alice state 2\");");
        checkRemoveOrder(alice, config, evals2, 4, 2, true);

        bytes[] memory evals3 = new bytes[](2);
        evals3[0] = bytes(":ensure(equal-to(get(1) 20) \"bob state 1\");");
        evals3[1] = bytes(":ensure(equal-to(get(2) 30) \"bob state 2\");");
        checkRemoveOrder(bob, config, evals3, 4, 2, true);
    }

    /// Removing a dead order is a noop so evals DO NOT run.
    function testRemoveOrderDeadOrder(address alice, OrderConfigV3 memory config) external {
        bytes[] memory evals = new bytes[](1);
        evals[0] = bytes(":ensure(0 \"always error\");");
        checkRemoveOrder(alice, config, evals, 0, 0, false);
    }

    /// A revert in the action prevents the order being removed.
    /// forge-config: default.assertions_revert = false
    /// forge-config: default.legacy_assertions = true
    function testRemoveOrderRevertInAction(address alice, OrderConfigV3 memory config) external {
        LibTestAddOrder.conformConfig(config, iInterpreter, iStore);
        vm.startPrank(alice);
        bytes[] memory evals0 = new bytes[](1);
        evals0[0] = bytes(":;");
        ActionV1[] memory actions = evalsToActions(evals0);
        bool stateChanged = iOrderbook.addOrder2(config, actions);
        assert(stateChanged);

        OrderV3 memory order = OrderV3(alice, config.evaluable, config.validInputs, config.validOutputs, config.nonce);

        assert(iOrderbook.orderExists(order.hash()));

        bytes[] memory evals1 = new bytes[](1);
        evals1[0] = bytes(":ensure(0 \"always revert\");");

        ActionV1[] memory actions1 = evalsToActions(evals1);

        vm.expectRevert("always revert");
        bool stateChanged2 = iOrderbook.removeOrder2(order, actions1);

        assert(!stateChanged2);

        assert(iOrderbook.orderExists(order.hash()));
    }
}
