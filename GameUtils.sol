// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GameUtils {    
    Position bluePlayerStart = Position(0, 0);
    Position redPlayerStart = Position(9, 9);
    
    BoardState[] playerColors = [BoardState.BLUE, BoardState.RED];


    function getOppositeColor(BoardState color) internal pure returns(BoardState) {
        if (color == BoardState.BLUE) {
            return BoardState.RED;
        }
        return BoardState.BLUE;
    }

    function setRandomNumberInRange(uint8 random, uint256 minValue, uint256 maxValue) internal pure returns(uint8) {
        require(maxValue >= minValue, "The uppper bound should be not less than the lower bound");
        return uint8(minValue) + (random % uint8(maxValue - minValue + 1));
    }
}

struct Position {
    uint256 row;
    uint256 column;
}

enum BoardState {
    FREE,
    BLUE,
    RED,
    TREE
}