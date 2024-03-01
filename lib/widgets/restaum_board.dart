import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../enums/messages.dart';
import '../enums/socket_events.dart';
import '../services/socket.dart';
import 'action_button.dart';

const Color graycolor = Colors.grey;
const Color blueColor = Colors.blue;

class RestaUmBoard extends StatefulWidget {
  const RestaUmBoard({super.key});

  @override
  State<RestaUmBoard> createState() => _RestaUmBoardState();
}

class _RestaUmBoardState extends State<RestaUmBoard> {
  bool canPlay = true;
  bool? hasFirst;
  Color? playerColor;
  final Color _currentColor = graycolor;
  final List<Color> _cells = change1PositionFilledList(31);
  final List<int> selectedIndex = [-1];
  final List<int> spotedIndex = [-1];
  final List _noBuild = [
    0,
    1,
    2,
    6,
    7,
    8,
    9,
    10,
    11,
    15,
    16,
    17,
    45,
    46,
    47,
    51,
    52,
    53,
    54,
    55,
    56,
    60,
    61,
    62
  ];
// _cells[31] = greenColor;
  final SocketClient _client = SocketClient();
  // List<GekitaiPiece> playersPieces = [];

  static List<Color> change1PositionFilledList(int pos) {
    List<Color> colors = List<Color>.filled(63, blueColor);
    colors[pos] = graycolor;
    return colors;
  }

  @override
  void initState() {
    super.initState();
    if (_client.socket.disconnected) {
      _client.connect();
    } else {
      final SnackBar snackbar = SnackBar(
        content: Text(Messages.connected),
        backgroundColor: Colors.green,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
    _handleComingMessage();
  }

  void _handlePlayerClick({required int tapedIndex, int? fromIndex}) {
    if (_isValidMoviment(tapedIndex: tapedIndex)) {
      setState(
        () {
          _cells[tapedIndex] = playerColor!;
        },
      );
      // playersPieces.removeLast();
      _client.sendBoardMove(
        playerColor: playerColor!,
        boardIndex: tapedIndex,
      );
      // _pushPieces(tapedIndex: tapedIndex);
      if (fromIndex != null) {
        setState(() {
          _handleMove(tapedIndex: tapedIndex, fromIndex: fromIndex);
        });
        _client.turnEnd(playerTurn: 1);
        _turnEnd();
        _checkWinner();
      }
    }
  }

  void _handleFirstPlayer() {
    _client.firstPlayer(playerTurn: 1);
  }

  void _handleComingMessage() {
    _client.socket.on(
      SocketEvents.boardMoviment.event,
      (data) {
        if (_isNotFirstMoviment()) _turnEnd();
        List<dynamic> move =
            data.toString().replaceAll('{', '').replaceAll('}', '').split(':');
        setState(
          () {
            _cells[int.parse(move[1])] = Color(int.parse(move[0]));
          },
        );
      },
    );

    _client.socket.on(
      SocketEvents.turnEnd.event,
      (data) {
        _turnStart();
      },
    );

    _client.socket.on(
      SocketEvents.firstPlayer.event,
      (data) {
        _hasFirst();
      },
    );

    _client.socket.on(
      SocketEvents.giveUp.event,
      (data) {
        _showGivUpRequest();
      },
    );

    _client.socket.on(
      SocketEvents.aceptGiveUp.event,
      (data) {
        final SnackBar snackbar = SnackBar(
          content: Text(Messages.loseByGivingUp),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
        _resetTheBoard();
      },
    );
  }

  void _showColorPicker() async {
    showDialog<Color>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  playerColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () {
                playerColor = null;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(playerColor);
              },
            ),
          ],
        );
      },
    ).then((selectedColor) {
      if (selectedColor != null) {
        playerColor = selectedColor;
        setState(
          () {},
        );
      }
    });
  }

  void _showGivUpRequest() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desistencia!'),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text('O adversário quer desistir do jogo!'),
                Text('Caso aceite , você será o  vencedor!')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Não Aceitar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'Aceitar',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                _aceptPlayerGivenUp();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVictory() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vencedor!'),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text('Parabéns, venceu o jogo!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                _aceptPlayerGivenUp();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isValidMoviment({required int tapedIndex}) {
    if (playerColor == null) {
      final SnackBar snackbar = SnackBar(
        content: Text(Messages.selectAColor),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      return false;
    }
    if (!canPlay) {
      final SnackBar snackbar = SnackBar(
        content: Text(
          Messages.waitYourTurn,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      return false;
    }
    return true;
  }

  void _hasFirst() {
    setState(() {
      canPlay = false;
      hasFirst = true;
    });
  }

  void _turnEnd() {
    setState(() {
      canPlay = false;
    });
  }

  void _turnStart() {
    setState(() {
      canPlay = true;
    });
  }

  bool _isNotFirstMoviment() {
    int grays = _cells.where((cell) => cell.value == graycolor.value).length;
    return grays > 1 ? false : true;
  }

  _handleMove({required int tapedIndex, required int fromIndex}) {
    _cells[tapedIndex] = Colors.blue;
    _cells[fromIndex] = Colors.grey;
    _client.sendBoardMove(
      playerColor: Colors.grey,
      boardIndex: fromIndex,
    );
    _client.sendBoardMove(
      playerColor: Colors.blue,
      boardIndex: tapedIndex,
    );

    int val = (tapedIndex - fromIndex).abs();
    if (val > 1) {
      int position =
          (val ~/ 2 + (tapedIndex > fromIndex ? fromIndex : tapedIndex));
      _cells[position] = Colors.grey;
      _client.sendBoardMove(
        playerColor: Colors.grey,
        boardIndex: position,
      );
    } else {
      int position = (tapedIndex > fromIndex ? fromIndex : tapedIndex + 1);
      _cells[position] = Colors.grey;
      _client.sendBoardMove(
        playerColor: Colors.grey,
        boardIndex: position,
      );
    }
  }

  _aceptPlayerGivenUp() {
    Navigator.of(context).pop();
    final SnackBar snackbar = SnackBar(
      content: Text(Messages.winTheGame),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    _client.socket.emit(SocketEvents.aceptGiveUp.event, 1);
    _resetTheBoard();
  }

  void _resetTheBoard() {
    for (int index = 0; index < _cells.length; index++) {
      if (!_noBuild.contains(index)) {
        _cells[index] = blueColor;
        _cells[31] = graycolor;
      }
    }
    setState(() {});
  }

  _checkWinner() {
    if (_cells.where((cell) => cell.value == blueColor.value).length == 1) {
      _showVictory();
    }

    for (int i = 0; i < 63; i++) {
      if (_noBuild.contains(i)) {
        return false;
      } else {
        if (i + 1 <= 63) {
          if (_cells[i + 1] == blueColor) return false;
        }
        if (i - 1 > 0) {
          if (_cells[i - 1] == blueColor) return false;
        }
        if (i + 10 <= 63) {
          if (_cells[i + 10] == blueColor) return false;
        }
        if (i - 10 > 0) {
          if (_cells[i - 10] == blueColor) return false;
        }
      }
      _showVictory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 400,
          width: 400,
          child: GridView.count(
            crossAxisCount: 9,
            children: List.generate(_cells.length, (index) {
              if (_noBuild.contains(index)) {
                return Container(
                  color: Colors.grey,
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    if (playerColor != null) {
                      if (selectedIndex[0] != index) {
                        if (selectedIndex[0] == -1) {
                          if (canPlay) {
                            setState(() {
                              selectedIndex[0] = index;
                              _cells[index] = playerColor!;
                            });
                            _handlePlayerClick(
                              tapedIndex: index,
                            );
                          } else {
                            final SnackBar snackbar = SnackBar(
                              content: Text(
                                Messages.waitYourTurn,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.yellow,
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackbar);
                          }
                        } else {
                          _handlePlayerClick(
                              tapedIndex: index, fromIndex: selectedIndex[0]);
                          selectedIndex[0] = -1;
                        }
                      } else {
                        setState(() {
                          selectedIndex[0] = -1;
                          _cells[index] = Colors.blue;
                        });
                        _client.sendBoardMove(
                          playerColor: Colors.blue,
                          boardIndex: index,
                        );
                      }
                    } else {
                      final SnackBar snackbar = SnackBar(
                        content: Text(
                          Messages.chooseColor,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor:
                            const Color.fromARGB(255, 169, 167, 150),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackbar);
                    }
                  },
                  child: Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: _cells[index],
                      child: Padding(
                        padding: const EdgeInsets.all(8), // Border radius
                        child: ClipOval(
                            child: Text(
                          index.toString(),
                          style: const TextStyle(color: Colors.white),
                        )),
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
        ),
        if (playerColor != null)
          if (hasFirst == null)
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasFirst = true;
                    _handleFirstPlayer();
                  });
                },
                child: const Text('Clique para ser o primeiro a jogar')),
        if (hasFirst == true && canPlay == true) const Text('Sua vez'),
        const SizedBox(
          height: 10,
        ),
        if (playerColor == null)
          ActionButton(
            callBack: _showColorPicker,
            textColor: Colors.red,
            label: 'Escolha uma cor',
          ),
        Row(
          children: [
            Container(
              height: 50,
              width: 150,
              // color: playerColor,
              decoration: BoxDecoration(
                  color: playerColor, borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text(
                  'Jogador',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [Container()],
        ),
        const SizedBox(
          height: 20,
        ),
        if (playerColor != null)
          ActionButton(
            callBack: _handleGivUp,
            textColor: Colors.blueAccent,
            label: 'Desistir',
          )
      ],
    );
  }

  _handleGivUp() {
    final SnackBar snackbar = SnackBar(
      content: Text(
        Messages.givUpRequest,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.yellowAccent,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    _client.giveUp(playerColor: playerColor!);
  }
}
