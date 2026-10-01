// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SumAmounts} from "../src/SumAmounts.sol";

contract SumAmountsTest {
    function _new() internal returns (SumAmounts) {
        return new SumAmounts();
    }

    function _assert(
        uint256 payment,
        uint256[3][] memory rows,
        uint256[] memory applied,
        uint256 unapplied
    ) internal {
        SumAmounts.Obligation[] memory obligations = new SumAmounts.Obligation[](rows.length);
        for (uint256 i = 0; i < rows.length; i++) {
            obligations[i] = SumAmounts.Obligation({id: rows[i][0], amountDue: rows[i][1], priority: rows[i][2]});
        }
        SumAmounts.Settlement memory got = _new().settle(payment, obligations);
        assert(got.unapplied == unapplied);
        assert(got.lines.length == applied.length);
        assert(got.lines.length == rows.length);
        for (uint256 i = 0; i < rows.length; i++) {
            assert(got.lines[i].id == rows[i][0]);
            assert(got.lines[i].applied == applied[i]);
        }
    }

    function _rows(uint256 count) internal pure returns (uint256[3][] memory rows) {
        rows = new uint256[3][](count);
    }

    function _applied(uint256 count) internal pure returns (uint256[] memory applied) {
        applied = new uint256[](count);
    }

    function test_empty() public {
        _assert(100, _rows(0), _applied(0), 100);
    }

    function test_pays_in_full() public {
        uint256[3][] memory rows = _rows(3);
        rows[0] = [uint256(1), 100, 1];
        rows[1] = [uint256(2), 40, 3];
        rows[2] = [uint256(3), 60, 2];
        uint256[] memory applied = _applied(3);
        applied[0] = 100;
        applied[1] = 40;
        applied[2] = 60;
        _assert(500, rows, applied, 300);
    }

    function test_higher_priority_is_paid_first() public {
        uint256[3][] memory rows = _rows(3);
        rows[0] = [uint256(1), 80, 1];
        rows[1] = [uint256(2), 50, 9];
        rows[2] = [uint256(3), 25, 9];
        uint256[] memory applied = _applied(3);
        applied[1] = 50;
        applied[2] = 10;
        _assert(60, rows, applied, 0);
    }

    function test_same_priority_pays_earlier_input_first() public {
        uint256[3][] memory rows = _rows(3);
        rows[0] = [uint256(1), 50, 1];
        rows[1] = [uint256(2), 30, 1];
        rows[2] = [uint256(3), 20, 1];
        uint256[] memory applied = _applied(3);
        applied[0] = 10;
        _assert(10, rows, applied, 0);
    }

    function test_remainder_spills_to_the_next_priority() public {
        uint256[3][] memory rows = _rows(3);
        rows[0] = [uint256(1), 100, 1];
        rows[1] = [uint256(2), 40, 5];
        rows[2] = [uint256(3), 60, 5];
        uint256[] memory applied = _applied(3);
        applied[0] = 20;
        applied[1] = 40;
        applied[2] = 60;
        _assert(120, rows, applied, 0);
    }

    function test_duplicate_id() public {
        SumAmounts.Obligation[] memory obligations = new SumAmounts.Obligation[](2);
        obligations[0] = SumAmounts.Obligation({id: 1, amountDue: 10, priority: 1});
        obligations[1] = SumAmounts.Obligation({id: 1, amountDue: 4, priority: 2});
        try _new().settle(5, obligations) returns (SumAmounts.Settlement memory) {
            assert(false);
        } catch (bytes memory reason) {
            assert(reason.length == 4);
            assert(keccak256(reason) == keccak256(abi.encodeWithSelector(SumAmounts.DuplicateId.selector)));
        }
    }
}
