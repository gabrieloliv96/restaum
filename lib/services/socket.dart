import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../enums/socket_events.dart';

class SocketClient {
  static final SocketClient _socketClient = SocketClient._internal();
  io.Socket socket = io.io('http://localhost:3000', {
    'autoConnect': false,
    'transports': ['websocket'],
  });

  SocketClient._internal();
  factory SocketClient() {
    return _socketClient;
  }

  connect() {
    socket.connect();
    socket.onConnectError((data) {});
  }

  sendMessage({required String message}) {
    socket.emit(SocketEvents.message.event, message);
  }

  sendBoardMove({required Color playerColor, required int boardIndex}) {
    Map<int, int> playerMove = {playerColor.value: boardIndex};
    socket.emit(SocketEvents.boardMoviment.event, playerMove.toString());
  }

  giveUp({
    required Color playerColor,
  }) {
    socket.emit(SocketEvents.giveUp.event, playerColor.toString());
  }

  turnEnd({required int playerTurn}) {
    Map turn = {'turn': playerTurn};
    socket.emit(
      SocketEvents.turnEnd.event,
      turn.toString(),
    );
  }

  firstPlayer({required int playerTurn}) {
    Map turn = {'turn': playerTurn};
    socket.emit(
      SocketEvents.firstPlayer.event,
      turn.toString(),
    );
  }
}
