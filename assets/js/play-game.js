import { Chessboard2 } from "@chrisoakman/chessboard2/dist/chessboard2.min.js";
import { Chess } from "chess.js";

let game;

export const PlayGameHook = {
  mounted() {
    let playerType = "watcher";
    if (
      this.el.getAttribute("phx-value-sessionid") ==
      this.el.getAttribute("phx-value-white")
    )
      playerType = "white";
    if (
      this.el.getAttribute("phx-value-sessionid") ==
      this.el.getAttribute("phx-value-black")
    )
      playerType = "black";

    game = new Game(this, {
      fen: this.el.getAttribute("phx-value-fen"),
      pgn: this.el.getAttribute("phx-value-pgn"),
      playerType,
    });

    this.handleEvent("move-done", (data) => game.makeMove(data.pgn));
  },
};

class Game {
  constructor(phx, { fen, pgn, playerType }) {
    this.phx = phx;
    this.pgn = pgn;
    this.playerType = playerType;
    this.chessboard = Chessboard2("board", {
      orientation: playerType === "black" ? "black" : "white",
      position: fen ?? "start",
      draggable: true,
      onDragStart: this.onDragStart.bind(this),
      onDrop: this.onDrop.bind(this),
    });
    this.game = new Chess(fen);
  }

  onDragStart(evt) {
    if (!this._canMove(evt.piece)) return false;

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
      const pgn = this.game.pgn();
      this.updateBoard();

      this.phx.pushEvent("move", { fen, pgn, move });
    } catch (e) {
      this.chessboard.clearCircles();
      return "snapback";
    }
  }

  updateBoard() {
    this.chessboard.clearCircles();
    this.chessboard.fen(this.game.fen());
  }

  makeMove(pgn) {
    this.game.loadPgn(pgn);
    this.updateBoard();
  }

  _canMove(piece) {
    // can't move if the game is over
    if (this.game.isGameOver()) return false;
    if (this.playerType === "watcher") return false;

    // can't move if if you don't have the white pieces on white's turn
    if (
      this.game.turn() === "w" &&
      (!/^w/.test(piece) || this.playerType !== "white")
    )
      return false;

    // can't move if you don't have the black pieces on black's turn
    if (
      this.game.turn() === "b" &&
      (!/^b/.test(piece) || this.playerType !== "black")
    )
      return false;

    return true;
  }
}
