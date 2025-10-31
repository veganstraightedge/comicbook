# AGENT.md - Development Rules

## Core Principles

- **Be terse, not verbose in responses** - Say as little as possible
- **One small move at a time** - No large changes
- **Always write tests first** - RSpec required
- **Easy to read code** - Clarity over cleverness
- **Follow existing patterns** - No new approaches

## Architecture Rules

### Adapter Pattern
```
Format (e.g., CBR)
├── cbr.rb - inherits from Adapter
├── archiver.rb - creates archives
└── extractor.rb - extracts archives
```

### TmpDir Testing
- All file I/O uses `Dir.mktmpdir`
- Never create files in repo root
- Clean up in `after` blocks

### Output Paths
- Use `determine_output_path` method
- Place files in source directory (temp)
- Never use current working directory

## Workflow Rules

### Before Coding
- Read existing code first
- Use `grep`/`find_path` to understand patterns
- Don't guess - investigate

### Development
- **Never commit without confirmation**
- Run tests - must pass
- Run RuboCop - must pass
- Provide one-line commit message

### Testing Requirements
- Match existing coverage
- Use `load_fixture().copy_to()` pattern for all test data
- Use RSpec matchers over raw Ruby (e.g., `expect(file).to exist` not `File.exist?`)
- Include: basic, edge cases, options, errors
- Follow existing spec structure exactly

## Quality Gates

### Definition of Done
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] RuboCop clean
- [ ] No repo root pollution
- [ ] Documentation updated
- [ ] Approved for commit

### Test Structure
```ruby
describe 'Component' do
  let(:temp_dir) { Dir.mktmpdir }
  after { FileUtils.rm_rf temp_dir }

  before do
    load_fixture('format/simple.ext').copy_to(test_file)
  end

  it 'uses RSpec matchers' do
    expect(File).to exist output_path
    expect(pages).to be_an Array
    expect(pages).to be_all ComicBook::Page
  end
end
```

## Adding New Formats

1. Create fixtures (same structure as others)
2. Main adapter (inherit from Adapter)
3. Extractor class
4. Archiver class (if possible)
5. Tests matching existing patterns
6. Update main ComicBook class detection
7. Update documentation

## Vendored Tools

- Use `lib/comic_book/vendor/platform/tool`
- Detect platform: macos/linux/windows
- Handle command errors gracefully
- Parse output appropriately

## Anti-Patterns

- Files in repo root
- Breaking existing interfaces
- New patterns when existing ones work
- Skipping quality gates
- Verbose communication

## Success Criteria

- All tests pass
- RuboCop clean
- Same patterns as CB7/CBT/CBZ
- No repo pollution
- Documentation current
