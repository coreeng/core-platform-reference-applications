import { readFileSync, writeFileSync } from "node:fs";

// Nextra 4.6.0 removes children before validating theme configuration, but its
// schema still requires children. Stable Zod correctly rejects that mismatch.
// Keep all configuration validation while excluding the separately rendered prop.
const layout = new URL("../node_modules/nextra-theme-docs/dist/layout.js", import.meta.url);
const original = "LayoutPropsSchema.safeParse(themeConfig)";
const patched = "LayoutPropsSchema.omit({ children: true }).safeParse(themeConfig)";
const source = readFileSync(layout, "utf8");

if (source.includes(original)) {
  if (source.split(original).length !== 2) {
    throw new Error("Unexpected Nextra layout; review the Zod compatibility patch.");
  }
  writeFileSync(layout, source.replace(original, patched));
} else if (!source.includes(patched)) {
  throw new Error("Nextra layout changed; review or remove the Zod compatibility patch.");
}
