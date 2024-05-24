import {
  draggable,
  dropTargetForElements,
} from "@atlaskit/pragmatic-drag-and-drop/element/adapter";

const HOVER_CLASSES = `
  before:h-16 before:sm:h-20 before:w-16 before:sm:w-20
  before:-mt-3 before:sm:-mt-4 before:-ml-3 before:sm:-ml-4
  before:bg-purple-200 before:bg-opacity-20
  before:inline-block before:z-10
  before:absolute before:rounded-full before:pointer-events-none`
  .trim()
  .split(/\s+/);

export const ElchesserHook = {
  mounted() {
    let moves = this.el.querySelector("#ec-moves");
    moves.scrollTo(0, moves.scrollHeight);

    registerDraggables(this);
    registerDropZones(this);
  },

  updated() {
    let moves = this.el.querySelector("#ec-moves");
    moves.scrollTo(0, moves.scrollHeight);

    // @TODO: We are constantly re-registering mostly duplicates here.
    // We should figure out a way to avoid doing this somehow.
    registerDraggables(this);
    registerDropZones(this);
  },
};

function registerDraggables(live) {
  live.el.querySelectorAll("[draggable]").forEach((el) => {
    draggable({
      element: el,
      getInitialData: () => ({
        color: el.dataset.color,
      }),
      canDrag: ({ element }) => {
        return element.dataset.color === live.el.dataset.activeColor;
      },
      onDragStart: (e) => {
        e.location.initial.dropTargets[0].element.click();
      },
    });
  });
}

function registerDropZones(live) {
  live.el.querySelectorAll("[data-square]").forEach((el) => {
    dropTargetForElements({
      element: el,
      onDragEnter: (e) => {
        e.location.current.dropTargets[0].element.classList.add(
          ...HOVER_CLASSES,
        );
      },
      onDragLeave: (e) => {
        e.location.previous.dropTargets[0].element.classList.remove(
          ...HOVER_CLASSES,
        );
      },
      onDrop: (e) => {
        e.location.current.dropTargets[0].element.classList.remove(
          ...HOVER_CLASSES,
        );

        e.location.current.dropTargets[0].element.click();
      },
    });
  });
}
