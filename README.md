# ComicBook

A Ruby library and CLI tool for managing comic books archives.

**`extract`** — to open a `.cb*` file.

**`archive`** — to create a `.cb*` file (default: `.cbz`).

Currently supported formats, `archive` and `extract`:
- CB7 — [7zip](https://en.wikipedia.org/wiki/7-Zip)
- CBT — [Tar](https://en.wikipedia.org/wiki/Tar_(computing))
- CBZ — [Zip](https://en.wikipedia.org/wiki/ZIP_(file_format))

Planned formats , only `extract`:

- **CBR** — [RAR](https://en.wikipedia.org/wiki/WinRAR) is proprietary without an open source implementation license. People use WinRAR (Windows-only) to create .rar files. Or `unrar` on Linux/macOS to open .rar files. Extracting support is provided because a large number of comic books are archived in .cbr/.rar format, primarily by Windows users. No support for creating `.cbr` files will ever be added until RAR is opensource (or reverse engineered).
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

In Ruby, you can use the `ComicBook` class to `extract` comic books archives from various formats. You `archive` a folder of images to create a comic book archive.

### Extracting

```ruby
ComicBook.extract 'path/to/archive.cbz'
```
### Archiving

```ruby
ComicBook.archive 'path/to/archive'
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
