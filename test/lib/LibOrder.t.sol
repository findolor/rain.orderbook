// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "forge-std/Test.sol";

import "src/lib/LibOrder.sol";

/// @title LibOrderTest
/// Exercises the LibOrder library.
contract LibOrderTest is Test {
    /// Hashing should always produce the same result for the same input.
    function testHashEqual(Order memory a) public {
        assertTrue(LibOrder.hash(a) == LibOrder.hash(a));
    }

    /// Hashing should always produce different results for different inputs.
    function testHashNotEqual(Order memory a, Order memory b) public {
        assertTrue(LibOrder.hash(a) != LibOrder.hash(b));
    }
}
