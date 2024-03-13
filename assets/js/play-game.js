import { Chessboard2 } from "@chrisoakman/chessboard2/dist/chessboard2.min.js";
import { Chess } from "chess.js";

let game;

export const PlayGameHook = {
  mounted() {
    game = new Game(this, this.el.getAttribute("phx-value-color"));

    this.handleEvent("move-done", (data) => game.makeMove(data.move));
  },
};

class Game {
  constructor(phx, color) {
    this.phx = phx;
    this.chessboard = Chessboard2("board", {
      orientation: color,
      position: "start",
      draggable: true,
      onDragStart: this.onDragStart.bind(this),
      onDrop: this.onDrop.bind(this),
    });
    this.game = new Chess();
  }

  onDragStart(evt) {
    if (this.game.isGameOver()) return false;

    if (this.game.turn === "w" && !/^w/.test(evt.piece)) return false;
    if (this.game.turn === "b" && !/^b/.test(evt.piece)) return false;

    this.game
      .moves({ square: evt.square, verbose: true })
      .forEach((move) => this.chessboard.addCircle(move.to));
  }

  onDrop(evt) {
    try {
      const move = {
        from: evt.source,
        to: evt.target,
        promotion: "q",
      };

      this.game.move(move);
      const fen = this.game.fen();
      this.updateBoard();

      this.phx.pushEvent("move", { fen, move });
    } catch (e) {
      this.chessboard.clearCircles();
      return "snapback";
    }
  }

  updateBoard() {
    this.chessboard.clearCircles();
    this.chessboard.fen(this.game.fen());
  }

  makeMove(move) {
    this.game.move(move);
    this.updateBoard();
  }
}
