// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "GameConstants.sol";
import "GameUtils.sol";

contract RoomController is GameConstants, GameUtils {
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

    function getMyIndex(uint256 roomId) external view onlyPlayerInRoom(roomId) returns(uint8) {
        Room storage room = rooms[roomId];
        for (uint8 i = 0; i < 2; i++) {
            if (room.players[i] == msg.sender) {
                return i;
            }
        }
        return 2;
    }

    function createRoom(address[] calldata players) external returns (uint256) {
        countRooms++;
        Room storage room = rooms[countRooms];
        room.players = players;
        for (uint256 i = 0; i < FIELD_HEIGHT; i++) {
            for (uint256 j = 0; j < FIELD_WIDTH; j++) {
                room.boardState[i][j] = BoardState.FREE;
            }
        }

        room.boardState[bluePlayerStart.row][bluePlayerStart.column] = BoardState.BLUE;
        room.boardState[redPlayerStart.row][redPlayerStart.column] = BoardState.RED;
        
        room.randomParameter = uint256(keccak256(abi.encodePacked(
            room.players[0], 
            room.players[1],
            countRooms,
            blockhash(block.number - 1)
        )));

        updateCurrentPlayerMoves(countRooms);
        generateTrees(countRooms);

        playerInRoom[players[0]] = countRooms;
        playerInRoom[players[1]] = countRooms;

        return countRooms;
    }

    function generateTrees(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        uint8[] memory random = new uint8[](32);
        uint256 currentRandom = 0;
        updateRandomValue(roomId);

        for (uint256 i = 0; i < 32; i++) {
            random[i] = uint8((room.randomParameter >> (8 * (31 - i))) & 0xFF);
        }
        uint256 amountOfTrees = TREES_MIN_AMOUNT + (random[currentRandom++]) % TREES_MAX_AMOUNT;

        for (uint256 i = 0; i < amountOfTrees; i++) {
            Position memory treePosition = Position(
                setRandomNumberInRange(random[currentRandom++], TREE_RANGE_MIN, TREE_RANGE_MAX),
                setRandomNumberInRange(random[currentRandom++], TREE_RANGE_MIN, TREE_RANGE_MAX)
                );
            room.boardState[treePosition.row][treePosition.column] = BoardState.TREE;
        }
    }

    function updateRandomValue(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        room.randomParameter = uint256(keccak256(abi.encodePacked(room.randomParameter, block.timestamp)));
    }

    function updateCurrentPlayerMoves(uint roomId) internal {
        Room storage room = rooms[roomId];
        updateRandomValue(roomId);
        room.currentPlayerMoves = uint256((room.randomParameter % 5) + 1);
    }

    function getCurrentPlayerMovesLeft(uint256 roomId) public view returns (uint256) {
        return rooms[roomId].currentPlayerMoves;
    }

    function getCurrentPlayerIndex(uint256 roomId) public view returns (uint256) {
        return rooms[roomId].currentPlayerIndex;
    }

    function getRoomIdByAddress(address player) external view returns (uint256) {
        return playerInRoom[player];
    }
}