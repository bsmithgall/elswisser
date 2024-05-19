import * as htmlToImage from "html-to-image";

export const ShareCaptureHook = {
  mounted() {
    const elId = this.el.dataset.captureTarget ?? "pair-share";
    const boundary = this.el.dataset.captureBounds ?? "clientBounds";
    const childSelector = this.el.dataset.captureChildren ?? null;

    this.el.addEventListener("click", async (_evt) => {
      await shareCapture({
        elId,
        boundary,
        childSelector,
        onSuccess: () => {
          this.liveSocket.main.isDead
            ? alert("Successfully copied to Clipboard!")
            : this.pushEvent("flash-copy-success");
        },
      });
    });
  },
};

export async function shareCapture({
  elId,
  boundary,
  childSelector,
  onSuccess,
}) {
  const el = elId instanceof HTMLElement ? elId : document.getElementById(elId);

  let opts;

  if (boundary === "complete") {
    opts = getEntireSnapshotOpts(el);
  } else if (boundary === "max-child") {
    opts = getWidestChildSnapshotOpts(el, childSelector);
  } else {
    opts = getBoundingSnapshotOpts(el);
  }

  try {
    if (boundary === "max-child") makeChildrenVisible(el, childSelector);
    const shareResult = await generateShare(el, opts);
    if (boundary === "max-child") ensureChildrenOverflow(el, childSelector);

    if (shareResult) onSuccess();
  } catch (err) {
    console.error(err);
  } finally {
    if (boundary === "max-child") ensureChildrenOverflow(el, childSelector);
  }
}

const generateShare = async (element, options) => {
  return "ClipboardItem" in window
    ? copyBlobToClipboard(element, options)
    : popBlobToWindow(element, options);
};

/**
 *
 * @param {HTMLElement} element
 * @returns {htmlToImage}
 */
const getBoundingSnapshotOpts = (element) => {
  const box = element.getBoundingClientRect();

  return {
    filter: (node) => !node.classList?.contains("js-screenshot-exclude"),
    height: box.height + 32,
    width: box.width + 32,
    style: {
      marginTop: 0,
      padding: "0.75rem 1rem",
      borderRadius: "0.35rem",
    },
  };
};

const getEntireSnapshotOpts = (element) => {
  return {
    filter: (node) => !node.classList?.contains("js-screenshot-exclude"),
    height: element.scrollHeight + 32,
    width: element.scrollWidth + 32,
    style: {
      marginTop: 0,
      padding: "0.75rem 1rem",
      borderRadius: "0.35rem",
    },
  };
};

const getWidestChildSnapshotOpts = (element, childSelector) => {
  return {
    filter: (node) => !node.classList?.contains("js-screenshot-exclude"),
    height: element.scrollHeight + 32,
    width:
      Math.max(
        ...[...element.querySelectorAll(childSelector)].map(
          (e) => e.scrollWidth,
        ),
      ) + 32,
    style: {
      marginTop: 0,
      padding: "0.75rem 1rem",
      borderRadius: "0.35rem",
    },
  };
};

const copyBlobToClipboard = async (element, options) => {
  const blob = await htmlToImage.toBlob(element, options);

  await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);

  return true;
};

const popBlobToWindow = async (element, options) => {
  const dataUri = await htmlToImage.toPng(element, options);

  const image = new Image();
  image.src = dataUri;

  let w = window.open("");

  w.document.write(
    `Your browser does not yet support ` +
      `<a target="_blank" href="https://caniuse.com/?search=ClipboardItem">ClipboardItem</a> :(. <br><br>` +
      image.outerHTML,
  );

  return false;
};

const makeChildrenVisible = (el, childSelector) => {
  el.classList.add("overflow-x-auto", "no-scrollbar");

  el.querySelectorAll(childSelector).forEach((e) =>
    e.classList.remove("overflow-x-auto"),
  );
};

const ensureChildrenOverflow = (el, childSelector) => {
  el.classList.remove("overflow-x-auto", "no-scrollbar");

  el.querySelectorAll(childSelector).forEach((e) => {
    e.classList.add("overflow-x-auto");
    console.log(e);
  });
};
