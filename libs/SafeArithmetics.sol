// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeArithmetics {
    enum Operation {
        ADD,
        SUB,
        MUL,
        DIV,
        POW
    }

    function safe(uint256 a, Operation op) internal pure returns (uint256) {
        return safe(a, op, a);
    }

    function safe(
        uint256 a,
        Operation op,
        uint256 b
    ) internal pure returns (uint256) {
        if (op == Operation.ADD) {
            a += b;
            require(a >= b);
        } else if (op == Operation.SUB) {
            a -= b;
            require(a <= b);
        } else if (op == Operation.MUL) {
            uint256 c = a;
            a *= b;
            require(safe(a, Operation.DIV, b) == c);
        } else if (op == Operation.DIV) {
            require(b != 0);
            a /= b;
        } else if (op == Operation.POW) {
            uint256 c = a;
            a ** b;
            require(a >= c || a == 1);
        }

        return a;
    }
}
