import * as htmlToImage from "html-to-image";

export const ShareCaptureHook = {
  mounted() {
    this.el.addEventListener("click", async (_evt) => {
      const el = document.getElementById("pair-share");
      try {
        const shareResult = await generateShare(el);
        if (shareResult) {
          this.pushEvent("flash-copy-success");
        }
      } catch (err) {
        console.error(err);
      }
    });
  },
};

export const generateShare = async (element) => {
  const options = getSnapshotOptions(element);

  return "ClipboardItem" in window
    ? copyBlobToClipboard(element, options)
    : popBlobToWindow(element, options);
};

/**
 *
 * @param {HTMLElement} element
 */
const getSnapshotOptions = (element) => {
  const box = element.getBoundingClientRect();

  return {
    height: box.height + 32,
    width: box.width + 32,
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
      image.outerHTML
  );

  return false;
};
