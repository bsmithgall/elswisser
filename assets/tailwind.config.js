// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "node_modules/@chrisoakman/chessboard2/dist/chessboard2.min.css",
  ],
  theme: {
    extend: {
      colors: {
        brand: "#15803d",
        boardwhite: {
          lighter: "#f6f8f7",
          DEFAULT: "#f2f5f3",
          darker: "#c9d5cd",
        },
        boardblack: {
          lighter: "#9ca7b1",
          DEFAULT: "#71828f",
          darker: "#606e7a",
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Hero Icons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./additional-icons");
      let values = {};

      fs.readdirSync(iconsDir).map((file) => {
        let name = path.basename(file, ".svg");
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });
      matchComponents(
        {
          icon: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--icon-${name}`]: `url('data:image/svg+xml;utf8,${encodeURIComponent(
                content
              )}')`,
              "-webkit-mask": `var(--icon-${name})`,
              mask: `var(--icon-${name})`,
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
    plugin(function ({ matchComponents, theme }) {
      let piecesDir = path.join(__dirname, "./pieces");
      let values = {};

      let colors = ["white", "black"];

      colors.forEach((color) => {
        fs.readdirSync(path.join(piecesDir, color)).map((file) => {
          let name = `${color}-${path.basename(file, ".svg")}`;
          values[name] = { name, fullPath: path.join(piecesDir, color, file) };
        });
      });

      matchComponents(
        {
          piece: ({ fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");

            return {
              "background-image": `url('data:image/svg+xml;base64,${Buffer.from(
                content
              ).toString("base64")}')`,
            };
          },
        },
        { values }
      );
    }),
  ],
};
