// eslint.config.js: ESLint 9 flat configuration for the team's own code.
const js = require('@eslint/js');
const globals = require('globals');
module.exports = [
  { ignores: ['node_modules/', 'coverage/', 'mock-bureau/'] },
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'commonjs',
      globals: { ...globals.node, ...globals.jest },
    },
  },
];
