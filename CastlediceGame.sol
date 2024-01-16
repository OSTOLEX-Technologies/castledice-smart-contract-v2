// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./GameConstants.sol";
import "./RoomController.sol";

contract CastlediceGame is GameConstants, RoomController {

    event FinishedGames(uint256 roomId, address winner);
    
    constructor() {
        countRooms = 0;
    }

    function makeMove(uint256 roomId, uint256 row, uint256 column) public onlyActivePlayer(roomId) returns(uint256){
        require(!isGameFinished(roomId), "Game is already finished");

        Room storage room = rooms[roomId];

        BoardState currentCellState = room.boardState[row][column];
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        require(currentCellState != currentPlayerColor, "You cannot make move on your cell");
        validateMove(roomId, row, column);

        if (currentCellState == BoardState.FREE) {
            require(room.currentPlayerMoves >= STANDART_MOVE_COST, "You don`t have enough moves left");
            room.currentPlayerMoves -= STANDART_MOVE_COST;
            room.boardState[row][column] = currentPlayerColor;
        } 
        else if (currentCellState == BoardState.TREE) {
            revert("You cannot move on a tree");
        }
        else {
            require(room.currentPlayerMoves >= STRIKE_MOVE_COST, "You don`t have enough moves left");
            room.currentPlayerMoves -= STRIKE_MOVE_COST;
            room.boardState[row][column] = currentPlayerColor;
            if (currentPlayerColor == BoardState.BLUE) {
                removeTails(roomId, BoardState.RED);
            }
            else {
                removeTails(roomId, BoardState.BLUE);
            }
        }

        if (room.currentPlayerMoves == 0) {
            updateCurrentPlayer(roomId);
        }

        if (isGameFinished(roomId)) {
            delete playerInRoom[room.players[0]];
            delete playerInRoom[room.players[1]];
        }

        return room.currentPlayerMoves;
    }

    function validateMove(uint256 roomId, uint256 row, uint256 column) internal view {
        Room storage room = rooms[roomId];

        bool nearCellPresent = false;
        BoardState currentPlayerColor = playerColors[room.currentPlayerIndex];

        for (int256 horizontalShift = -1; horizontalShift <= 1; horizontalShift++) {
            for (int256 verticalShift = -1; verticalShift <= 1; verticalShift++) {
                int256 currRow = int256(row) + verticalShift;
                int256 currColumn = int256(column) + horizontalShift;
                if (currRow < 0 || currColumn < 0) {
                    continue;
                }
                if (currRow >= int256(FIELD_HEIGHT) || currColumn >= int256(FIELD_WIDTH)) {
                    continue;
                }
                uint256 uCurrRow = uint256(currRow);
                uint256 uCurrColumn = uint256(currColumn);

                if (uCurrRow == row && uCurrColumn == column) {
                    continue;
                }
                if (room.boardState[uCurrRow][uCurrColumn] == currentPlayerColor) {
                    nearCellPresent = true;
                    break;
                }
            }
        }
        require(nearCellPresent, "Move is invalid: there is no cell with the same color nearby");
    }

    function getBoardArray(uint256 roomId) external view returns (uint8[] memory) {
        Room storage room = rooms[roomId];
        uint8[] memory result = new uint8[](FIELD_HEIGHT * FIELD_WIDTH);
        for (uint256 row = 0; row < FIELD_HEIGHT; row++) {
            for (uint256 column = 0; column < FIELD_WIDTH; column++) {
                result[row * FIELD_WIDTH + column] = uint8(room.boardState[row][column]);
            }
        }
        return result;
    }

    function removeTails(uint256 roomId, BoardState colorToRemove) internal {
        Position memory playerStartPosition = redPlayerStart;
        if (colorToRemove == BoardState.BLUE) {
            playerStartPosition = bluePlayerStart;
        }
        Room storage room = rooms[roomId];
        bool[FIELD_HEIGHT][FIELD_WIDTH] memory isGood;
        isGood[playerStartPosition.row][playerStartPosition.column] = true;
        uint8[] memory stack = new uint8[](FIELD_HEIGHT * FIELD_WIDTH * 2);
        uint256 currentStack = 0;
        
        stack[currentStack++] = uint8(playerStartPosition.row);
        stack[currentStack++] = uint8(playerStartPosition.column);

        while (currentStack > 0) {
            int256 column = int256(uint256(stack[--currentStack]));
            int256 row = int256(uint256(stack[--currentStack]));
            
            for (int256 verticalShift = -1; verticalShift <= 1; verticalShift++) {
                if (row + verticalShift >= 0 && row + verticalShift < int256(FIELD_HEIGHT)) {
                    for (int256 horizontalShift = -1; horizontalShift <= 1; horizontalShift++) {
                        if (column + horizontalShift >= 0 && column + horizontalShift < int256(FIELD_WIDTH)) {
                            uint256 currentRow = uint256(row + verticalShift);
                            uint256 currentColumn = uint256(column + horizontalShift);
                            if (room.boardState[currentRow][currentColumn] == colorToRemove &&
                                !isGood[currentRow][currentColumn]
                            ) {
                                isGood[currentRow][currentColumn] = true;
                                stack[currentStack++] = uint8(currentRow);
                                stack[currentStack++] = uint8(currentColumn);
                            }
                        }
                    }
                }
            }
        }
        for (uint256 row = 0; row < FIELD_HEIGHT; row++) {
            for (uint256 column = 0; column < FIELD_WIDTH; column++) {
                if (room.boardState[row][column] == colorToRemove && !isGood[row][column]) {
                    room.boardState[row][column] = BoardState.FREE;
                }
            }
        }
    }

    function updateCurrentPlayer(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        require(room.currentPlayerMoves == 0, "Previous player still has moves");
        updateCurrentPlayerMoves(roomId);
        room.currentPlayerIndex ^= 1;
    }

    function isGameFinished(uint256 roomId) public view returns (bool) {
        Room storage room = rooms[roomId];
        return room.boardState[0][0] == BoardState.RED || room.boardState[9][9] == BoardState.BLUE;
    }

    function getGameWinner(uint256 roomId) public view returns (address) {
        Room storage room = rooms[roomId];
        if (room.boardState[bluePlayerStart.row][bluePlayerStart.column] == BoardState.RED) {
            return room.players[1];
        }
        if (room.boardState[redPlayerStart.row][redPlayerStart.column] == BoardState.BLUE) {
            return room.players[0];
        }
        revert("Game is not finished, there is no winner");
    }

    // moves => [row[0], col[0], row[1], col[1], row[2]...]
    function makeBatchedMoves(uint256 roomId, uint8[] calldata moves) external {
        require(moves.length % 2 == 0, "Invalid batch of moves");

        for (uint8 i = 0; i + 1 < moves.length; i += 2) {
            makeMove(roomId, moves[i], moves[i + 1]);
        }
    }
}