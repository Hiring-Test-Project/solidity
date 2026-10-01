// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SumAmounts {
    error NotImplemented();
    error DuplicateId();

    struct Obligation {
        uint256 id;
        uint256 amountDue;
        uint256 priority;
    }

    struct Line {
        uint256 id;
        uint256 applied;
    }

    struct Settlement {
        Line[] lines;
        uint256 unapplied;
    }

    function settle(uint256, Obligation[] calldata) external pure returns (Settlement memory) {
        revert NotImplemented();
    }
}
