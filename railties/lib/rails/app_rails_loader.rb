require 'pathname'

module Rails
  module AppRailsLoader
    RUBY = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
    EXECUTABLES = ['bin/rails', 'script/rails']
    BUNDLER_WARNING = <<EOS
Looks like your app's ./bin/rails is a stub that was generated by Bundler.

In Rails 4, your app's bin/ directory contains executables that are versioned
like any other source code, rather than stubs that are generated on demand.

Here's how to upgrade:

  bundle config --delete bin    # Turn off Bundler's stub generator
  rake rails:update:bin         # Use the new Rails 4 executables
  git add bin                   # Add bin/ to source control

You may need to remove bin/ from your .gitignore as well.

When you install a gem whose executable you want to use in your app,
generate it and add it to source control:

  bundle binstubs some-gem-name
  git add bin/new-executable

EOS

    def self.exec_app_rails
      original_cwd = Dir.pwd

      loop do
        if exe = find_executable
          contents = File.read(exe)

          if contents =~ /(APP|ENGINE)_PATH/
            exec RUBY, exe, *ARGV
            break # non reachable, hack to be able to stub exec in the test suite
          elsif exe.end_with?('bin/rails') && contents.include?('This file was generated by Bundler')
            $stderr.puts(BUNDLER_WARNING)
            Object.const_set(:APP_PATH, File.expand_path('config/application', Dir.pwd))
            require File.expand_path('../boot', APP_PATH)
            require 'rails/commands'
            break
          end
        end

        # If we exhaust the search there is no executable, this could be a
        # call to generate a new application, so restore the original cwd.
        Dir.chdir(original_cwd) and return if Pathname.new(Dir.pwd).root?

        # Otherwise keep moving upwards in search of an executable.
        Dir.chdir('..')
      end
    end

    def self.find_executable
      EXECUTABLES.find { |exe| File.exists?(exe) }
    end
  end
end
