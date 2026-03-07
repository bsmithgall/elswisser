/**
 * Pure functions that sync a cytoscape instance with step/snapshot data.
 *
 * Every function takes the cytoscape instance (and any auxiliary state
 * it needs) as explicit arguments — no `this` references.
 */

function fmtNum(n) {
  return Number.isInteger(n) ? n.toString() : n.toFixed(1);
}

/**
 * One-time setup: add nodes + edges from the initial snapshot and run
 * a circle layout.  Returns the `edgeKeys` array that later update
 * functions need for edge lookups.
 *
 * `vertexLabelsMap` is an optional map of `{ "0": "Alice", "1": "Bob" }`
 * for displaying player names instead of raw vertex numbers.
 */
export function initGraph(cy, snapshot, vertexLabelsMap) {
  const elements = [];

  for (const [v] of Object.entries(snapshot.vertex_labels)) {
    const displayName = (vertexLabelsMap && vertexLabelsMap[v]) || v;
    elements.push({
      group: "nodes",
      data: { id: `n${v}`, label: displayName, vertexId: v, displayName },
    });
  }

  const edgeKeys = [];
  for (const [k, [x, y, w]] of Object.entries(snapshot.edges)) {
    const edgeId = `e${k}`;
    edgeKeys.push({ id: edgeId, key: k, x, y, w });
    elements.push({
      group: "edges",
      data: {
        id: edgeId,
        source: `n${x}`,
        target: `n${y}`,
        label: `${w}`,
        x,
        y,
        w,
      },
    });
  }

  cy.add(elements);
  cy.layout({ name: "circle", animate: false }).run();
  cy.nodes().forEach((n) => n.lock());

  return edgeKeys;
}

/**
 * Apply S / T / unlabeled classes to nodes.
 */
export function updateLabels(cy, snapshot) {
  for (const [v, label] of Object.entries(snapshot.vertex_labels)) {
    const node = cy.getElementById(`n${v}`);
    node.removeClass("s-label t-label");
    if (label === "s") node.addClass("s-label");
    else if (label === "t") node.addClass("t-label");
  }
}

/**
 * Apply the `matched` class to edges that are in the current matching.
 */
export function updateMatched(cy, edgeKeys, snapshot) {
  cy.edges().removeClass("matched");

  const matchedSet = new Set();
  for (const [x, y] of snapshot.matched_edges) {
    matchedSet.add(`${Math.min(x, y)}-${Math.max(x, y)}`);
  }

  for (const { id, x, y } of edgeKeys) {
    const key = `${Math.min(x, y)}-${Math.max(x, y)}`;
    if (matchedSet.has(key)) {
      cy.getElementById(id).addClass("matched");
    }
  }
}

/**
 * Rebuild blossom compound nodes from the snapshot.
 */
export function updateBlossoms(cy, snapshot) {
  cy.nodes(":parent").forEach((p) => {
    p.children().move({ parent: null });
    cy.remove(p);
  });

  for (let i = 0; i < snapshot.blossoms.length; i++) {
    const b = snapshot.blossoms[i];
    const parentId = `blossom-${i}`;

    cy.add({
      group: "nodes",
      data: {
        id: parentId,
        label: `B [${b.dual}]`,
      },
    });

    for (const v of b.vertices) {
      const node = cy.getElementById(`n${v}`);
      if (node.length > 0) {
        node.move({ parent: parentId });
      }
    }
  }
}

/**
 * Update vertex dual labels and detect budget changes.
 * Returns a `dualChanges` map `{ v: { from, to } }` for vertices
 * whose budget changed this step.
 */
export function updateDuals(cy, snapshot, prevDuals) {
  cy.nodes().removeClass("budget-changed");

  const dualChanges = {};

  for (const [v, dual] of Object.entries(snapshot.vertex_duals)) {
    const node = cy.getElementById(`n${v}`);
    const name = node.data("displayName") || v;
    node.data("label", `${name}\n${fmtNum(dual)}`);

    if (prevDuals[v] !== undefined && prevDuals[v] !== dual) {
      dualChanges[v] = { from: prevDuals[v], to: dual };
      node.addClass("budget-changed");
    }
    prevDuals[v] = dual;
  }

  return dualChanges;
}

/**
 * Highlight the active vertex/edges and annotate scan-step edges
 * with slack arithmetic.
 */
export function updateActive(cy, edgeKeys, type, detail, dualChanges) {
  cy.elements().removeClass(
    "active edge-grow edge-s-to-s edge-tight-t edge-delta2 edge-delta3 grow-target s-to-s-target",
  );

  // Restore original weight labels
  for (const { id, w } of edgeKeys) {
    cy.getElementById(id).data("label", `${w}`);
  }

  if (type === "scan_step" && detail.vertex !== undefined) {
    cy.getElementById(`n${detail.vertex}`).addClass("active");

    // Hide labels on all edges first, then show formulas on classified ones
    const classifiedEdges = new Set();

    if (detail.neighbor_edges) {
      for (const ne of detail.neighbor_edges) {
        const cls = ne.classification;
        if (cls === "internal") continue;

        classifiedEdges.add(ne.edge);
        const edgeEl = cy.getElementById(`e${ne.edge}`);
        const nodeEl = cy.getElementById(`n${ne.neighbor}`);

        if (cls === "grow") {
          edgeEl.addClass("edge-grow");
          nodeEl.addClass("grow-target");
        } else if (cls === "s_to_s") {
          edgeEl.addClass("edge-s-to-s");
          nodeEl.addClass("s-to-s-target");
        } else if (cls === "tight_t") {
          edgeEl.addClass("edge-tight-t");
        } else if (cls === "delta2") {
          edgeEl.addClass("edge-delta2");
        } else if (cls === "delta3") {
          edgeEl.addClass("edge-delta3");
        }

        edgeEl.data(
          "label",
          `${fmtNum(ne.x_budget)}+${fmtNum(ne.y_budget)}−2×${ne.weight}=${fmtNum(ne.slack_2x)}`,
        );
      }
    }

    // Suppress labels on non-classified edges during scan steps
    for (const { id, key } of edgeKeys) {
      if (!classifiedEdges.has(Number(key))) {
        cy.getElementById(id).data("label", "");
      }
    }
  }

  if (type === "delta_step") {
    if (detail.edge !== undefined) {
      cy.getElementById(`e${detail.edge}`).addClass("active");
    }

    for (const [v, change] of Object.entries(dualChanges)) {
      const node = cy.getElementById(`n${v}`);
      const name = node.data("displayName") || v;
      node.data(
        "label",
        `${name}\n${fmtNum(change.from)}→${fmtNum(change.to)}`,
      );
    }
  }

  if (type === "augment" && detail.path_edges) {
    for (const edgeIdx of detail.path_edges) {
      cy.getElementById(`e${edgeIdx}`).addClass("active");
    }
  }
}

/**
 * Apply terminal styling when the algorithm has finished.
 */
export function showFinalMatching(cy, edgeKeys, snapshot) {
  const matchedVertices = new Set();
  for (const [x, y] of snapshot.matched_edges) {
    matchedVertices.add(String(x));
    matchedVertices.add(String(y));
  }

  cy.elements().removeClass("s-label t-label active budget-changed");

  const matchedSet = new Set();
  for (const [x, y] of snapshot.matched_edges) {
    matchedSet.add(`${Math.min(x, y)}-${Math.max(x, y)}`);
  }
  for (const { id, x, y } of edgeKeys) {
    const key = `${Math.min(x, y)}-${Math.max(x, y)}`;
    if (matchedSet.has(key)) {
      cy.getElementById(id).addClass("final-matched");
    }
  }

  for (const [v] of Object.entries(snapshot.vertex_labels)) {
    const node = cy.getElementById(`n${v}`);
    if (matchedVertices.has(v)) {
      node.addClass("final-matched");
    } else {
      node.addClass("final-unmatched");
    }
  }
}
