# RSpec Coding Standards

## Best Practices
- Never test private methods directly. All private methods should be tested through their public interface. Tests should be written in a way, though, that will test that the private method behaves correctly when called through the public interface.
- Always use `subject` to test the main call being tested
- Do not use aliases for `subject`, e.g., `subject(:alias_name)` unless needed for some variation of subject. In the case where a variation is needed, the main call should not be aliased, but subsequent calls can be.
- Use `described_class` wherever possible
- Do not assign variables inside `it` blocks. Variables may be assigned in `before` blocks, but whenever possible, all variables should be set in `let` or `let!` statements.
- Only use `let!` when eager loading is required. Wherever possible allow it to lazy load.
