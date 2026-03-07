/**
 * Cytoscape stylesheet for the matching visualizer.
 *
 * Colors are keyed by their Tailwind name so the mapping to HEEx
 * template classes is explicit.  If you change a color here, update
 * the corresponding Tailwind class in the Elixir templates too.
 */

const c = {
  white: "#fff",

  // zinc
  zinc400: "#9ca3af",
  zinc500: "#6b7280",
  zinc700: "#374151",

  // slate
  slate200: "#cbd5e1",
  slate400: "#94a3b8",
  slate700: "#334155",

  // gray
  gray300: "#d1d5db",
  gray400: "#9ca3af",

  // blue
  blue500: "#3b82f6",
  blue700: "#1d4ed8",
  blue800: "#1e40af",

  // red
  red500: "#ef4444",
  red700: "#b91c1c",
  red800: "#991b1b",

  // green
  green500: "#22c55e",
  green600: "#16a34a",
  green700: "#15803d",

  // yellow
  yellow400: "#facc15",

  // amber
  amber500: "#f59e0b",

  // violet
  violet400: "#a78bfa",
  violet500: "#8b5cf6",
  violet600: "#7c3aed",

  // orange
  orange500: "#f97316",
};

const CYTOSCAPE_STYLE = [
  // ── Nodes ──────────────────────────────────────────────────────
  {
    selector: "node",
    style: {
      "background-color": c.zinc400,
      label: "data(label)",
      "text-valign": "center",
      "text-halign": "center",
      "font-size": "9px",
      "font-weight": "bold",
      color: c.white,
      "text-outline-color": c.zinc700,
      "text-outline-width": 1.5,
      "text-wrap": "wrap",
      "text-max-width": "60px",
      width: 32,
      height: 32,
      "border-width": 2,
      "border-color": c.zinc500,
    },
  },
  {
    selector: "node.s-label",
    style: {
      "background-color": c.blue500,
      "border-color": c.blue700,
      "text-outline-color": c.blue800,
    },
  },
  {
    selector: "node.t-label",
    style: {
      "background-color": c.red500,
      "border-color": c.red700,
      "text-outline-color": c.red800,
    },
  },
  {
    selector: "node.active",
    style: {
      "border-width": 4,
      "border-color": c.yellow400,
      "border-style": "double",
    },
  },
  {
    selector: "node.budget-changed",
    style: {
      "border-width": 3,
      "border-color": c.amber500,
    },
  },

  // ── Edges ──────────────────────────────────────────────────────
  {
    selector: "edge",
    style: {
      "line-color": c.slate200,
      width: 2,
      "curve-style": "bezier",
      label: "data(label)",
      "font-size": "9px",
      "font-weight": "bold",
      "text-rotation": "none",
      color: c.slate700,
      "text-background-color": c.white,
      "text-background-opacity": 1,
      "text-background-padding": "3px",
      "text-background-shape": "rectangle",
    },
  },
  {
    selector: "edge.matched",
    style: {
      "line-color": c.green500,
      width: 5,
      "line-style": "solid",
      "z-index": 1,
    },
  },
  {
    selector: "edge.active",
    style: {
      "line-color": c.yellow400,
      width: 4,
      "z-index": 3,
    },
  },
  {
    selector: "edge.edge-grow",
    style: {
      "line-color": c.green500,
      width: 3,
      "z-index": 2,
    },
  },
  {
    selector: "edge.edge-s-to-s",
    style: {
      "line-color": c.amber500,
      width: 3,
      "z-index": 2,
    },
  },
  {
    selector: "edge.edge-tight-t",
    style: {
      "line-color": c.slate400,
      width: 2,
      "line-style": "dashed",
      "z-index": 2,
    },
  },
  {
    selector: "edge.edge-delta2",
    style: {
      "line-color": c.violet500,
      width: 2,
      "line-style": "dashed",
      "z-index": 2,
    },
  },
  {
    selector: "edge.edge-delta3",
    style: {
      "line-color": c.orange500,
      width: 2,
      "line-style": "dashed",
      "z-index": 2,
    },
  },

  // ── Scan-step node highlights ──────────────────────────────────
  {
    selector: "node.grow-target",
    style: {
      "border-width": 3,
      "border-color": c.green500,
    },
  },
  {
    selector: "node.s-to-s-target",
    style: {
      "border-width": 3,
      "border-color": c.amber500,
    },
  },

  // ── Final-state styling ────────────────────────────────────────
  {
    selector: "edge.final-matched",
    style: {
      "line-color": c.green600,
      width: 7,
      "z-index": 3,
    },
  },
  {
    selector: "node.final-matched",
    style: {
      "background-color": c.green600,
      "border-color": c.green700,
      "border-width": 3,
      "text-outline-color": c.green700,
    },
  },
  {
    selector: "node.final-unmatched",
    style: {
      "background-color": c.gray300,
      "border-color": c.gray400,
      opacity: 0.6,
    },
  },

  // ── Blossoms (compound / parent nodes) ─────────────────────────
  {
    selector: ":parent",
    style: {
      "background-color": c.violet400,
      "background-opacity": 0.08,
      "border-color": c.violet600,
      "border-width": 2,
      "border-style": "dashed",
      label: "data(label)",
      "text-valign": "top",
      "text-halign": "center",
      "font-size": "10px",
      "font-weight": "bold",
      color: c.violet600,
      "text-outline-color": c.white,
      "text-outline-width": 1,
      padding: "16px",
    },
  },

  // ── Transitions ────────────────────────────────────────────────
  {
    selector: "*",
    style: {
      "transition-property":
        "background-color, line-color, width, border-width, border-color, opacity",
      "transition-duration": "0.45s",
    },
  },
];

export default CYTOSCAPE_STYLE;
