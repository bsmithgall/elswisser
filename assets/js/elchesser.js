export const ElchesserHook = {
  mounted() {
    let moves = this.el.querySelector("#ec-moves");
    moves.scrollTo(0, moves.scrollHeight);
  },

  updated() {
    let moves = this.el.querySelector("#ec-moves");
    moves.scrollTo(0, moves.scrollHeight);
  },
};
