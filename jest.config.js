// jest.config.js: run only the team's tests in test/, not the kit's node --test files.
module.exports = {
  roots: ['<rootDir>/test'],
  testEnvironment: 'node',
};
