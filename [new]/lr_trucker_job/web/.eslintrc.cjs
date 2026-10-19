module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'react-hooks', 'react-refresh'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
  ],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': ['error', {argsIgnorePattern: '^_'}],
    // shadcn modules intentionally co-locate components, variants and hooks.
    'react-refresh/only-export-components': 'off',
  },
  overrides: [
    {
      files: ['vite.config.ts', 'vitest.config.ts', 'playwright.config.ts'],
      env: {node: true},
    },
  ],
};
