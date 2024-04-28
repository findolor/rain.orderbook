// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {
    TakeOrderConfigV3,
    IO,
    OrderV3,
    SignedContextV1,
    IOrderBookV4,
    TakeOrdersConfigV3,
    OrderConfigV3,
    ClearConfig,
    EvaluableV3,
    ActionV1
} from "rain.orderbook.interface/interface/unstable/IOrderBookV4.sol";
import {IERC3156FlashBorrower} from "rain.orderbook.interface/interface/ierc3156/IERC3156FlashBorrower.sol";

contract FlashLendingMockOrderBook is IOrderBookV4 {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        receiver.onFlashLoan(msg.sender, token, amount, 0, data);
        return true;
    }

    function enact(ActionV1[] calldata) external pure {}

    /// @inheritdoc IOrderBookV4
    function takeOrders2(TakeOrdersConfigV3 calldata) external pure returns (uint256, uint256) {
        return (0, 0);
    }

    /// @inheritdoc IOrderBookV4
    function addOrder2(OrderConfigV3 calldata, ActionV1[] calldata) external pure returns (bool) {
        return false;
    }

    function orderExists(bytes32) external pure returns (bool) {
        return false;
    }

    /// @inheritdoc IOrderBookV4
    function clear2(
        OrderV3 memory,
        OrderV3 memory,
        ClearConfig calldata,
        SignedContextV1[] memory,
        SignedContextV1[] memory
    ) external {}
    function deposit2(address, uint256, uint256, ActionV1[] calldata) external {}
    function flashFee(address, uint256) external view returns (uint256) {}
    function maxFlashLoan(address) external view returns (uint256) {}
    function removeOrder2(OrderV3 calldata, ActionV1[] calldata) external returns (bool) {}

    function vaultBalance(address, address, uint256) external view returns (uint256) {}
    function withdraw2(address, uint256, uint256, ActionV1[] calldata) external {}
}
