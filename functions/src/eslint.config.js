import globals from "globals";
import pluginJs from "@eslint/js";


/** @type {import('eslint').Linter.Config[]} */
export default [
  {
    languageOptions: {
      globals: globals.browser, // Enable browser global variables
    },
    plugins: {
      js: pluginJs, // Load the ESLint plugin
    },
    rules: {
      // Add custom rules here
      "no-unused-vars": "warn", // Example: warn on unused variables
    },
  },
];