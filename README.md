# AppImage to App

A command-line tool to easily convert AppImages into native-like desktop applications.

## Features

- Convert AppImages into searchable desktop applications
- Automatically create desktop entries
- Extract application metadata
- List all converted applications
- Remove converted applications
- Custom naming and categorization

## Installation

```bash
gem install appimage-to-app
```

## Usage

### Convert an AppImage

```bash
ata convert /path/to/app.AppImage
```

With custom name and category:

```bash
ata convert /path/to/app.AppImage --name "My App" --category "Development"
```

### List converted applications

```bash
ata list
```

### Remove a converted application

```bash
ata remove "My App"
```

## Development

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Run tests:
   ```bash
   bundle exec rspec
   ```
4. Build the gem:
   ```bash
   gem build appimage-to-app.gemspec
   ```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 