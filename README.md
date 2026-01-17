# ComicBook

⚠️ Under construction. ⚠️
A Ruby library and CLI tool for managing comic books archives.

**`extract`** — to open a `.cb*` file.

**`archive`** — to create a `.cb*` file (default: `.cbz`).

Currently supported formats for `archive` and `extract`:
- CB7 — [7zip](https://en.wikipedia.org/wiki/7-Zip)
- CBT — [Tar](https://en.wikipedia.org/wiki/Tar_(computing))
- CBZ — [Zip](https://en.wikipedia.org/wiki/ZIP_(file_format))

Currently supported formats for `extract` only:
- **CBR** — [RAR](https://en.wikipedia.org/wiki/WinRAR) is proprietary without an open source implementation license. Extracting support is provided using vendored [`unar`](https://theunarchiver.com/command-line) binaries because a large number of comic books are archived in .cbr/.rar format. No support for creating `.cbr` files will ever be added until RAR is open source (or reverse engineered).

Planned formats for `extract` only:
- **CBA** — [ACE](https://en.wikipedia.org/wiki/WinAce) is both proprietary and very old/outdated/unsupported. ACE extracting support is provided for historical posterity and completeness.

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
bundle add comicbook
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install comicbook
```

## Usage

### CLI

```sh
# Extract a comic book archive
comicbook extract path/to/archive.cbz

# Extract to a specific destination
comicbook extract path/to/archive.cbz --to path/to/output

# Extract only image files (exclude metadata like ComicInfo.xml)
comicbook extract path/to/archive.cbz --images-only

# Create a comic book archive from a folder
comicbook archive path/to/folder

# Create archive at a specific destination
comicbook archive path/to/folder --to path/to/output.cbz

# Show help
comicbook --help
```

### Ruby API

```ruby
# Extract a comic book archive (extracts all files by default)
ComicBook.extract 'path/to/archive.cbz'

# Extract to a specific destination
ComicBook.extract 'path/to/archive.cbz', to: 'path/to/output'

# Extract only image files (exclude metadata like ComicInfo.xml)
ComicBook.extract 'path/to/archive.cbz', images_only: true

# Create a comic book archive from a folder (creates .cbz by default)
ComicBook.new('path/to/folder').archive

# Create archive at a specific destination
ComicBook.new('path/to/folder').archive to: 'path/to/output.cbz'

# Get pages from an archive
comic = ComicBook.new 'path/to/archive.cbz'
comic.pages  # => [#<ComicBook::Page>, ...]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veganstraightedge/comicbook. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/veganstraightedge/comicbook/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Comicbook project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/veganstraightedge/comicbook/blob/main/CODE_OF_CONDUCT.md).
