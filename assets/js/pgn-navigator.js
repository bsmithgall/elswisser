import { Chessboard2 } from "@chrisoakman/chessboard2/dist/chessboard2.min.js";
import { Chess } from "chess.js";
import hotkeys from "hotkeys-js";

// handle the time between the page loading and the mount completing.
if (document.getElementById("pgn-board")) {
  Chessboard2("pgn-board", { position: "start" });
}

let navigator;

export const GameNavigatorHook = {
  mounted() {
    navigator = new PgnNavigator(this.el.getAttribute("phx-value-pgn"));
  },

  beforeUpdate() {
    navigator = navigator.clone();
  },
};

class PgnNavigator {
  constructor(rawPgn) {
    this.rawPgn = rawPgn;
    this.chessboard = Chessboard2("pgn-board", { position: "start" });
    this.game = new Chess();
    this.game.loadPgn(rawPgn);
    this.moves = this.game.history({ verbose: true });
    this._moveNumber = 0;

    this.initializeListeners();
    this.initializeHotkeys();
  }

  clone() {
    navigator = new PgnNavigator(this.rawPgn);
    navigator.moveNumber = this.moveNumber;
    return navigator;
  }

  get moveNumber() {
    return this._moveNumber;
  }

  set moveNumber(_moveNumber) {
    this._moveNumber = _moveNumber;
  }

  initializeListeners() {
    document.querySelectorAll("button[data-js-navigate]").forEach((el) => {
      el.addEventListener("click", (e) => {
        switch (el.getAttribute("data-js-navigate")) {
          case "forward":
            e.preventDefault();
            this.forward();
            break;
          case "back":
            e.preventDefault();
            this.back();
            break;
          case "start":
            e.preventDefault();
            this.start();
            break;
          case "end":
            e.preventDefault();
            this.end();
            break;
          default:
            break;
        }
      });
    });
  }

  initializeHotkeys() {
    hotkeys("right", () => this.forward());
    hotkeys("left", () => this.back());
  }

  start() {
    this.moveNumber = 0;
    this.setBoard();
  }

  end() {
    this.moveNumber = this.moves.length;
    this.setBoard();
  }

  forward() {
    this.moveNumber = Math.min(this.moveNumber + 1, this.moves.length);
    this.setBoard();
  }

  back() {
    this.moveNumber = Math.max(this.moveNumber - 1, 0);
    this.setBoard();
  }

  setBoard() {
    const position =
      this.moveNumber === this.moves.length
        ? this.moves[this.moveNumber - 1].after
        : this.moves[this.moveNumber].before;

    this.chessboard.setPosition(position);
  }
}
