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
    this.prevDuals = {};

    this.handleEvent("step", (data) => this.onStep(data));
    this.handleEvent("reset", () => this.onReset());
  },

  onReset() {
    this.cy.elements().remove();
    this.initDone = false;
    this.edgeKeys = [];
    this.prevDuals = {};
  },

  onStep(data) {
    const { type, detail, snapshot, vertex_labels_map } = data;

    this.cy.elements().removeClass("final-matched final-unmatched");

    if (!this.initDone) {
      this.edgeKeys = initGraph(this.cy, snapshot, vertex_labels_map);
      this.initDone = true;
    }

    updateLabels(this.cy, snapshot);
    updateMatched(this.cy, this.edgeKeys, snapshot);
    updateBlossoms(this.cy, snapshot);
    const dualChanges = updateDuals(this.cy, snapshot, this.prevDuals);
    updateActive(this.cy, this.edgeKeys, type, detail, dualChanges);

    if (type === "stage_end" && detail && detail.augmented === false) {
      showFinalMatching(this.cy, this.edgeKeys, snapshot);
    }
  },

  destroyed() {
    if (this.cy) {
      this.cy.destroy();
    }
  },
};
