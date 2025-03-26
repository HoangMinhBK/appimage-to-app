# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'pathname'
require 'colorize'

module AppimageToApp
  class CLI < Thor
    desc 'convert PATH', 'Convert an AppImage into a desktop application'
    method_option :name, type: :string, aliases: '-n', desc: 'Custom name for the application'
    method_option :category, type: :string, aliases: '-c', default: 'Utility', desc: 'Application category (e.g., Development, Graphics, Office)'
    method_option :icon, type: :string, aliases: '-i', desc: 'Path to custom icon file (PNG, SVG, or XPM)'
    method_option :comment, type: :string, aliases: '-m', desc: 'Application description/comment'
    method_option :keywords, type: :string, aliases: '-k', desc: 'Keywords for searching (comma-separated)'
    method_option :terminal, type: :boolean, aliases: '-t', default: false, desc: 'Run in terminal'
    method_option :startup_notify, type: :boolean, aliases: '-s', default: true, desc: 'Enable startup notification'
    method_option :startup_wm_class, type: :string, aliases: '-w', desc: 'Startup WM class for startup notification'
    
    def convert(path)
      appimage_path = Pathname.new(path).expand_path
      
      unless appimage_path.exist?
        say "Error: File not found: #{path}", :red
        exit 1
      end
      
      unless valid_appimage?(appimage_path)
        say "Error: Not a valid AppImage: #{path}", :red
        exit 1
      end
      
      begin
        # Make AppImage executable
        FileUtils.chmod(0o755, appimage_path)
        
        # Extract metadata
        metadata = extract_metadata(appimage_path)
        
        # Create desktop entry
        create_desktop_entry(appimage_path, metadata)
        
        # Install AppImage
        install_appimage(appimage_path)
        
        say "Successfully converted #{appimage_path.basename} into a desktop application", :green
      rescue StandardError => e
        say "Error converting AppImage: #{e.message}", :red
        exit 1
      end
    end
    
    desc 'list', 'List all converted applications'
    def list
      desktop_dir = Pathname.new(ENV['HOME']) / '.local/share/applications'
      return unless desktop_dir.exist?
      
      Dir.glob("#{desktop_dir}/*.desktop").each do |entry|
        entry_path = Pathname.new(entry)
        if entry_path.read.include?('AppImage')
          say entry_path.basename('.desktop')
        end
      end
    end
    
    desc 'remove NAME', 'Remove a converted application'
    def remove(name)
      desktop_file = Pathname.new(ENV['HOME']) / '.local/share/applications' / "#{name}.desktop"
      
      if desktop_file.exist?
        desktop_file.delete
        say "Removed desktop entry for #{name}", :green
      else
        say "No desktop entry found for #{name}", :yellow
      end
    end
    
    private
    
    def valid_appimage?(path)
      # Check if file is executable and has AppImage header
      File.executable?(path) && File.read(path, 8).start_with?("\x7fELF")
    end
    
    def extract_metadata(appimage_path)
      # TODO: Implement metadata extraction from AppImage
      {
        name: options[:name] || appimage_path.basename('.AppImage').to_s,
        category: options[:category],
        icon: options[:icon] || 'application-x-executable',
        comment: options[:comment],
        keywords: options[:keywords],
        terminal: options[:terminal],
        startup_notify: options[:startup_notify],
        startup_wm_class: options[:startup_wm_class]
      }
    end
    
    def create_desktop_entry(appimage_path, metadata)
      desktop_dir = Pathname.new(ENV['HOME']) / '.local/share/applications'
      desktop_dir.mkpath
      
      desktop_file = desktop_dir / "#{metadata[:name]}.desktop"
      
      content = <<~DESKTOP
        [Desktop Entry]
        Name=#{metadata[:name]}
        Exec=#{appimage_path}
        Icon=#{metadata[:icon]}
        Type=Application
        Categories=#{metadata[:category]};
        Terminal=#{metadata[:terminal]}
        StartupNotify=#{metadata[:startup_notify]}
      DESKTOP
      
      # Add optional fields if they are provided
      content += "Comment=#{metadata[:comment]}\n" if metadata[:comment]
      content += "Keywords=#{metadata[:keywords]}\n" if metadata[:keywords]
      content += "StartupWMClass=#{metadata[:startup_wm_class]}\n" if metadata[:startup_wm_class]
      
      desktop_file.write(content)
      FileUtils.chmod(0o644, desktop_file)
    end
    
    def install_appimage(appimage_path)
      apps_dir = Pathname.new(ENV['HOME']) / '.local/bin'
      apps_dir.mkpath
      
      dest_path = apps_dir / appimage_path.basename
      FileUtils.cp(appimage_path, dest_path)
      FileUtils.chmod(0o755, dest_path)
    end
  end
end 