// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GameConstants {
    uint256 constant public FIELD_HEIGHT = 10;
    uint256 constant public FIELD_WIDTH = 10;  
    uint256 constant STANDART_MOVE_COST = 1;
    uint256 constant STRIKE_MOVE_COST = 3;
    uint256 constant TREE_RANGE_MIN = 2;
    uint256 constant TREE_RANGE_MAX = 7;
    uint256 constant TREES_MIN_AMOUNT = 1;
    uint256 constant TREES_MAX_AMOUNT = 5;
}