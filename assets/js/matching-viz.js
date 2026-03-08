import cytoscape from "cytoscape";

import CYTOSCAPE_STYLE from "./matching-viz/styles";
import {
  initGraph,
  updateLabels,
  updateMatched,
  updateBlossoms,
  updateDuals,
  updateActive,
  showFinalMatching,
} from "./matching-viz/graph-updates";

function fmtNum(n) {
  return Number.isInteger(n) ? n.toString() : n.toFixed(1);
}

export const MatchingVizHook = {
  mounted() {
    this.cy = cytoscape({
      container: this.el,
      style: CYTOSCAPE_STYLE,
      userZoomingEnabled: false,
      userPanningEnabled: false,
      boxSelectionEnabled: false,
      autoungrabify: true,
    });

    this.initDone = false;
    this.edgeKeys = [];

    this.handleEvent("step", (data) => this.onStep(data));
    this.handleEvent("reset", () => this.onReset());

    // Floating tooltip for edge slack decomposition (scan steps only)
    this.tooltip = document.createElement("div");
    Object.assign(this.tooltip.style, {
      position: "fixed",
      zIndex: "1000",
      display: "none",
      pointerEvents: "none",
      fontFamily: "ui-monospace, monospace",
      fontSize: "11px",
      lineHeight: "1.7",
      background: "white",
      border: "1px solid #e4e4e7",
      borderRadius: "6px",
      boxShadow: "0 2px 8px rgba(0,0,0,0.10)",
      padding: "7px 10px",
      color: "#3f3f46",
      whiteSpace: "nowrap",
    });
    document.body.appendChild(this.tooltip);

    this.cy.on("mouseover", "edge", (evt) => {
      const info = evt.target.data("slackInfo");
      if (!info) return;

      const xLabel =
        this.cy.getElementById(`n${info.x}`).data("displayName") ||
        `${info.x}`;
      const yLabel =
        this.cy.getElementById(`n${info.y}`).data("displayName") ||
        `${info.y}`;
      const twoW = 2 * info.weight;

      this.tooltip.innerHTML = [
        `budget[${xLabel}]&nbsp;=&nbsp;${fmtNum(info.x_budget)}`,
        `budget[${yLabel}]&nbsp;=&nbsp;${fmtNum(info.y_budget)}`,
        `2 &times; weight&nbsp;=&nbsp;2 &times; ${info.weight} = ${twoW}`,
        `<span style="display:block;border-top:1px solid #e4e4e7;margin:3px 0"></span>`,
        `slack&nbsp;=&nbsp;${fmtNum(info.slack_2x)}`,
      ].join("<br>");

      const { clientX, clientY } = evt.originalEvent;
      this.tooltip.style.left = `${clientX + 14}px`;
      this.tooltip.style.top = `${clientY - 10}px`;
      this.tooltip.style.display = "block";
    });

    this.cy.on("mousemove", "edge", (evt) => {
      if (this.tooltip.style.display === "none") return;
      const { clientX, clientY } = evt.originalEvent;
      this.tooltip.style.left = `${clientX + 14}px`;
      this.tooltip.style.top = `${clientY - 10}px`;
    });

    this.cy.on("mouseout", "edge", () => {
      this.tooltip.style.display = "none";
    });
  },

  onReset() {
    this.cy.elements().remove();
    this.initDone = false;
    this.edgeKeys = [];
  },

  onStep(data) {
    const { type, detail, snapshot, vertex_labels_map, prev_duals } = data;

    this.cy.elements().removeClass("final-matched final-unmatched");

    if (!this.initDone) {
      this.edgeKeys = initGraph(this.cy, snapshot, vertex_labels_map);
      this.initDone = true;
    }

    updateLabels(this.cy, snapshot);
    updateMatched(this.cy, this.edgeKeys, snapshot);
    updateBlossoms(this.cy, snapshot);
    const dualChanges = updateDuals(this.cy, snapshot, prev_duals);
    updateActive(this.cy, this.edgeKeys, type, detail, dualChanges);

    if (type === "stage_end" && detail && detail.augmented === false) {
      showFinalMatching(this.cy, this.edgeKeys, snapshot);
    }
  },

  destroyed() {
    if (this.cy) this.cy.destroy();
    if (this.tooltip) this.tooltip.remove();
  },
};
