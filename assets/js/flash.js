export const FlashHook = {
  mounted() {
    const timeoutAfter = parseInt(
      this.el.getAttribute("phx-value-fade-after") ?? "2000"
    );
    const flashVisible = window.getComputedStyle(this.el).display !== "none";

    if (flashVisible && timeoutAfter !== -1) {
      setTimeout(() => this.el.click(), timeoutAfter);
    }
  },
};
