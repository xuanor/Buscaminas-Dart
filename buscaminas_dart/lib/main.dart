import 'dart:io';
import 'dart:math';

const int rows = 6;
const int cols = 10;
const int numMines = 8;

class Casella {
  bool mina = false;
  bool descoberta = false;
  bool bandera = false;
  int minesAdjacents = 0;
}

void main() {
  final tauler =
      List.generate(rows, (_) => List.generate(cols, (_) => Casella()));
  final aleatori = Random();
  inicialitzaTauler(tauler, aleatori);
  int tirades = 0;
  bool perdu = false;

  while (!perdu) {
    mostraTauler(tauler, false);
    stdout.write("Escriu una comanda: ");
    final input = stdin.readLineSync()?.toUpperCase() ?? '';
    if (input == 'TRAMPES' || input == 'CHEAT') {
      mostraTauler(tauler, true);
      continue;
    } else if (input == 'HELP' || input == 'AJUDA') {
      mostraAjuda();
      continue;
    }

    if (RegExp(r'^[A-F][0-9]( FLAG| BANDERA)?$').hasMatch(input)) {
      final fila = input.codeUnitAt(0) - 'A'.codeUnitAt(0);
      final columna = int.parse(input[1]);

      if (input.endsWith('FLAG') || input.endsWith('BANDERA')) {
        tauler[fila][columna].bandera = !tauler[fila][columna].bandera;
        continue;
      } else {
        if (!tauler[fila][columna].bandera) {
          perdu = destapaCasella(tauler, fila, columna, true, true);
          tirades++;
        }
      }
    } else {
      print("Comanda no vàlida. Escriu 'ajuda' per veure les instruccions.");
    }
  }

  mostraTauler(tauler, true);
  print(perdu ? "Has perdut!" : "Has guanyat!");
  print("Número de tirades: $tirades");
}

void inicialitzaTauler(List<List<Casella>> tauler, Random aleatori) {
  int minesColocades = 0;

  while (minesColocades < numMines) {
    final fila = aleatori.nextInt(rows);
    final columna = aleatori.nextInt(cols);

    // Verifica restriccions: mínim 2 mines per quadrant
    if (!tauler[fila][columna].mina &&
        compleixRestriccions(tauler, fila, columna)) {
      tauler[fila][columna].mina = true;
      minesColocades++;
    }
  }
}

bool compleixRestriccions(List<List<Casella>> tauler, int fila, int columna) {
  final quadrants = [
    {'minRow': 0, 'maxRow': rows ~/ 2, 'minCol': 0, 'maxCol': cols ~/ 2},
    {'minRow': 0, 'maxRow': rows ~/ 2, 'minCol': cols ~/ 2, 'maxCol': cols},
    {'minRow': rows ~/ 2, 'maxRow': rows, 'minCol': 0, 'maxCol': cols ~/ 2},
    {'minRow': rows ~/ 2, 'maxRow': rows, 'minCol': cols ~/ 2, 'maxCol': cols},
  ];

  for (var quadrant in quadrants) {
    int countMines = 0;
    for (int r = quadrant['minRow']!; r < quadrant['maxRow']!; r++) {
      for (int c = quadrant['minCol']!; c < quadrant['maxCol']!; c++) {
        if (tauler[r][c].mina) countMines++;
      }
    }

    // Si en un quadrant hi ha menys de 2 mines, no es pot posar una nova mina aquí
    if (countMines < 2) {
      if (fila >= quadrant['minRow']! &&
          fila < quadrant['maxRow']! &&
          columna >= quadrant['minCol']! &&
          columna < quadrant['maxCol']!) {
        return true; // Es pot posar la mina
      }
      return false; // No es pot posar
    }
  }

  return true; // Si no hi ha restriccions, es pot posar la mina
}

bool destapaCasella(List<List<Casella>> tauler, int x, int y,
    bool esPrimeraJugada, bool esJugadaUsuari) {
  if (x < 0 ||
      x >= rows ||
      y < 0 ||
      y >= cols ||
      tauler[x][y].descoberta ||
      tauler[x][y].bandera) {
    return false;
  }

  if (tauler[x][y].mina) {
    if (esPrimeraJugada) {
      mouMina(tauler, x, y);
    } else if (esJugadaUsuari) {
      return true;
    } else {
      return false;
    }
  }

  tauler[x][y].descoberta = true;
  tauler[x][y].minesAdjacents = comptaMinesAdjacents(tauler, x, y);

  if (tauler[x][y].minesAdjacents == 0) {
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if (dx != 0 || dy != 0) {
          destapaCasella(tauler, x + dx, y + dy, false, false);
        }
      }
    }
  }

  return false;
}

void mouMina(List<List<Casella>> tauler, int x, int y) {
  final aleatori = Random();
  while (true) {
    final novaX = aleatori.nextInt(rows);
    final novaY = aleatori.nextInt(cols);
    if (!tauler[novaX][novaY].mina && !tauler[novaX][novaY].descoberta) {
      tauler[novaX][novaY].mina = true;
      tauler[x][y].mina = false;
      break;
    }
  }
}

int comptaMinesAdjacents(List<List<Casella>> tauler, int x, int y) {
  int comptador = 0;
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < rows && ny >= 0 && ny < cols && tauler[nx][ny].mina) {
        comptador++;
      }
    }
  }
  return comptador;
}

void mostraTauler(List<List<Casella>> tauler, bool mostrarMines) {
  print(" 0123456789");
  for (var i = 0; i < rows; i++) {
    stdout.write(String.fromCharCode('A'.codeUnitAt(0) + i));
    for (var j = 0; j < cols; j++) {
      final casella = tauler[i][j];
      if (casella.bandera) {
        stdout.write('#');
      } else if (!casella.descoberta) {
        stdout.write('·');
      } else if (casella.mina && mostrarMines) {
        stdout.write('*');
      } else {
        stdout
            .write(casella.minesAdjacents == 0 ? ' ' : casella.minesAdjacents);
      }
    }
    print('');
  }
}

void mostraAjuda() {
  print("""
Comandes disponibles:
- Escollir casella: [lletra fila][número columna] (exemple: B2)
- Posar/treure bandera: [lletra fila][número columna] FLAG o BANDERA
- Mostrar trampes: TRAMPES o CHEAT
- Ajuda: HELP o AJUDA
  """);
}
