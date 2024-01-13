// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "BoardController.sol";
import "GameConstants.sol";

contract RoomController is BoardController, GameConstants {
     struct Room {
        address[] players;
        uint256 currentPlayerIndex;
        BoardState[FIELD_HEIGHT][FIELD_WIDTH] boardState;
        uint256 currentPlayerMoves;
        uint256 randomParameter;
    }

    mapping(uint256 => Room) public rooms;
    mapping(address => uint256) public playerInRoom;

    uint256 public countRooms;

    constructor() {
        countRooms = 0;
    }

    modifier onlyActivePlayer(uint roomId) {
        uint256 playerIndex = rooms[roomId].currentPlayerIndex;

        require(rooms[roomId].players[playerIndex] == msg.sender,
                "It is not your turn to make a move");
        _;
    }

    modifier onlyPlayerInRoom(uint roomId) {
        Room storage room = rooms[roomId];
        require(room.players[0] == msg.sender || room.players[1] == msg.sender, "It is not your room");
        _;
    }
}