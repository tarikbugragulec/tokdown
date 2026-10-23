# Contributing to TokDown

First off, thank you for considering contributing to TokDown! 🎉

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/tarikbugragulec/tokdown.git
   cd tokdown
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run the test suite:
   ```bash
   bundle exec rspec
   ```

4. Check code style:
   ```bash
   bundle exec rubocop
   ```

## Pull Request Guidelines

- Ensure all existing and new specs pass.
- Write unit tests for any new compression features or edge cases.
- Follow standard Ruby community style conventions (enforced via RuboCop).
- Update `README.md` if changing public APIs or CLI options.
