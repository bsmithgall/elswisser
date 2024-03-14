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
      playerType,
    });

    this.handleEvent("move-done", (data) => game.makeMove(data.move));
  },
};

class Game {
  constructor(phx, { fen, playerType }) {
    this.phx = phx;
    this.playerType = playerType;
    this.chessboard = Chessboard2("board", {
      orientation: playerType === "black" ? "black" : "white",
      position: fen ?? "start",
      draggable: true,
      onDragStart: this.onDragStart.bind(this),
      onDrop: this.onDrop.bind(this),
    });
    this.game = new Chess();
  }

  onDragStart(evt) {
    if (!this.canMove(evt.piece)) return false;

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

  canMove(piece) {
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
