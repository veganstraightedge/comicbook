# ComicBook Ruby - System Documentation

## Overview

ComicBook Ruby is a Ruby library for reading, writing, and manipulating comic book archive files. It provides a unified interface for working with multiple comic book formats including CBZ (ZIP), CB7 (7-Zip), CBT (TAR), CBR (RAR), and CBA (ACE) archives.

## Project Structure

```
comicbook-ruby/
├── lib/
│   ├── comicbook.rb              # Main entry point and public API
│   └── comic_book/
│       ├── adapter.rb            # Base adapter class
│       ├── page.rb               # Page representation
│       ├── version.rb            # Version constant
│       ├── cli_helpers.rb        # CLI utility functions
│       ├── cb7.rb               # CB7 (7-Zip) adapter
│       ├── cb7/
│       │   ├── archiver.rb      # CB7 archive creation
│       │   └── extractor.rb     # CB7 archive extraction
│       ├── cbt.rb               # CBT (TAR) adapter
│       ├── cbt/
│       │   ├── archiver.rb      # CBT archive creation
│       │   └── extractor.rb     # CBT archive extraction
│       ├── cbz.rb               # CBZ (ZIP) adapter
│       ├── cbz/
│       │   ├── archiver.rb      # CBZ archive creation
│       │   └── extractor.rb     # CBZ archive extraction
│       └── vendor/              # Vendored dependencies
├── spec/                        # RSpec test suite
│   ├── fixtures/                # Test fixtures for all formats
│   └── comic_book/              # Organized test files
└── bin/                         # Executables and development tools
```

## Architecture

### Core Design Patterns

#### 1. Adapter Pattern
The system uses the Adapter pattern to provide a unified interface across different comic book archive formats. Each format (CBZ, CB7, CBT, etc.) implements the same interface defined by `ComicBook::Adapter`.

```ruby
class ComicBook::Adapter
  def archive(options = {})      # Create archive from folder (to: destination_path)
  def extract(options = {})      # Extract archive to folder (to: destination_path)
  def pages                      # Get array of Page objects
end
```

#### 2. Strategy Pattern
The main `ComicBook` class acts as a context that delegates to the appropriate adapter based on file type detection:

```ruby
def adapter
  case type
  when :cb7 then CB7.new path
  when :cbt then CBT.new path
  when :cbz then CBZ.new path
  # ... other formats
  end
end
```

#### 3. Template Method Pattern
Each adapter family (CB7, CBT, CBZ) follows a consistent structure with separate Archiver and Extractor classes that implement format-specific operations while sharing common patterns.

### Key Components

#### 1. ComicBook (Main Class)
- **Location**: `lib/comicbook.rb`
- **Purpose**: Public API entry point and file type detection
- **Responsibilities**:
  - File type detection based on extensions
  - Path validation
  - Delegation to appropriate adapters
  - Unified interface for all operations

#### 2. ComicBook::Adapter (Base Class)
- **Location**: `lib/comic_book/adapter.rb`
- **Purpose**: Abstract base class for all format adapters
- **Pattern**: Template method defining common interface
- **Key Methods**: `archive`, `extract`, `pages`

#### 3. Format Adapters
Each format has three components:

**Main Adapter** (`cb7.rb`, `cbt.rb`, `cbz.rb`)
- Inherits from `ComicBook::Adapter`
- Delegates to Archiver/Extractor classes
- Implements `pages` method for reading archive contents

**Archiver Classes** (`*/archiver.rb`)
- Handles creation of archives from source folders
- Implements format-specific compression
- Manages file filtering (images only)
- Supports options like custom extensions and delete_original

**Extractor Classes** (`*/extractor.rb`)
- Handles extraction of archives to folders
- Implements format-specific decompression
- Filters extracted files (images only)
- Supports custom destinations and extensions

#### 4. ComicBook::Page
- **Location**: `lib/comic_book/page.rb`
- **Purpose**: Represents a single page/image within a comic archive
- **Attributes**: `path` (file path), `name` (display name)

### File Type Support

| Format | Extension | Status | Compression | Dependencies |
|--------|-----------|--------|-------------|--------------|
| CBZ | `.cbz` | ✅ Full | ZIP | `rubyzip` gem |
| CB7 | `.cb7` | ✅ Full | 7-Zip | `seven-zip` gem |
| CBT | `.cbt` | ✅ Full | TAR | Ruby stdlib |
| CBR | `.cbr` | 🚧 Planned | RAR | TBD |
| CBA | `.cba` | 🚧 Planned | ACE | TBD |

### Data Flow

#### Archive Creation Flow
1. User calls `ComicBook.new(folder_path).archive()`
2. Main class detects folder type
3. Delegates to CBZ adapter (default for folders)
4. CBZ creates Archiver instance
5. Archiver scans folder for image files
6. Creates ZIP archive with filtered content
7. Returns path to created archive

#### Archive Extraction Flow
1. User calls `ComicBook.new(archive_path).extract()`
2. Main class detects file type by extension
3. Delegates to appropriate adapter (CB7, CBT, CBZ)
4. Adapter creates Extractor instance
5. Extractor reads archive contents
6. Filters for image files only
7. Extracts to destination folder
8. Returns path to extracted folder

#### Page Reading Flow
1. User calls `ComicBook.new(archive_path).pages`
2. Main class delegates to appropriate adapter
3. Adapter reads archive contents
4. Filters for image files
5. Creates Page objects with path and name
6. Returns sorted array of Page objects

## Configuration & Constants

### Image File Support
```ruby
IMAGE_EXTENSIONS   = %w[.jpg .jpeg .png .gif .bmp .webp].freeze
IMAGE_GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,webp}'.freeze
```

The system automatically filters files to include only recognized image formats when creating or extracting archives.

### Options Support
All archive and extract operations support these options:
- `extension`: Custom file extension for output
- `delete_original`: Boolean to remove source after operation
- `destination`: Custom output path

## Dependencies

### Runtime Dependencies
- **rubyzip** (>= 3.2.1): ZIP file handling for CBZ format
- **seven-zip** (~> 1.4): 7-Zip handling for CB7 format
- Ruby stdlib: TAR handling for CBT format

### Development Dependencies
- **rspec**: Testing framework
- **rspec-file_fixtures**: Fixture management for tests
- **rubocop**: Code linting and style enforcement

## Testing Strategy

### Test Organization
- **Unit Tests**: Individual component testing
- **Integration Tests**: End-to-end format operations
- **Fixture-Based**: Real archive files for accurate testing

### TmpDir Pattern
All tests use `Dir.mktmpdir` for file I/O operations to ensure:
- No files created in repository root
- Proper cleanup after each test
- Isolation between test runs

### Test Coverage
- 173 examples across all components
- Full coverage of archive/extract/pages operations
- Edge cases: empty archives, non-image files, nested folders

## Performance Considerations

### Memory Usage
- Streaming operations where possible
- No full file loading into memory for large archives
- Lazy page enumeration

### File I/O
- Temporary directory usage prevents repository pollution
- Atomic operations with proper cleanup
- Path normalization for cross-platform compatibility

## Error Handling

### Exception Hierarchy
```ruby
ComicBook::Error < StandardError
```

### Common Error Cases
- Unsupported file types
- Missing dependencies for format handlers
- Invalid or corrupted archive files
- Permission issues during file operations

## Future Extensibility

### Adding New Formats
1. Create new adapter class inheriting from `ComicBook::Adapter`
2. Implement archiver and extractor classes
3. Add format detection to main `ComicBook` class
4. Add comprehensive test suite following existing patterns

### Plugin Architecture
The adapter pattern makes it easy to add new formats or extend existing ones without modifying core functionality.

## Version Information
- **Current Version**: 0.1.0
- **Ruby Requirement**: >= 3.4.7
- **License**: MIT
