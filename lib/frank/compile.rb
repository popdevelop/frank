require 'yui/compressor'

class String
  def starts_with?(characters)
      self.match(/^#{characters}/) ? true : false
  end
end

module Frank
  class Compile < Frank::Base

    class << self
      include Frank::Render

      # compile the templates
      # if production and template isn't index and is html
      # name a folder based on the template and compile to index.html
      # otherwise compile as is
      def compile_templates
        dir = File.join(Frank.root, Frank.dynamic_folder)

        Dir[File.join(dir, '**{,/*/**}/*')].each do |path|
          if File.file?(path) && !File.basename(path).match(/^(\.|_)/)
            path    = path[ (dir.size + 1)..-1 ]
            ext     = File.extname(path)
            new_ext = ext_from_handler(ext)
            name    = File.basename(path, ext)

            # No suitable handler found
            if not new_ext.is_a? String
              next
            end

            if Frank.production? && "#{name}.#{new_ext}" != 'index.html' && new_ext == 'html'
              new_file = File.join(Frank.export.path, path.sub(/(\/?[\w-]+)\.[\w-]+$/, "\\1/index.#{new_ext}"))
            else
              new_file = File.join(Frank.export.path, path.sub(/\.[\w-]+$/, ".#{new_ext}"))
            end

            create_dirs(new_file)
            File.open(new_file, 'w') {|f| f.write render(path) }
            puts " - \033[32mCreating\033[0m '#{new_file}'" unless Frank.silent_export?
          end
        end
      end

      # use path to determine folder name and
      # create the required folders if they don't exist
      def create_dirs(path)
        FileUtils.makedirs path.split('/').reverse[1..-1].reverse.join('/')
      end

      def read_binary_file(path)
        File.open(path, 'rb') {|f| f.read }
      end

      # copies over static content
      def copy_static
        puts " - \033[32mCopying\033[0m static content" unless Frank.silent_export?
        static_folder = File.join(Frank.root, Frank.static_folder)
        FileUtils.cp_r(File.join(static_folder, '/.'), Frank.export.path)
      end

      def package_javascripts
        return if Frank.assets == nil

        output_dir = File.join(Frank.export.path, Frank.assets[:package_path])
        Dir.mkdir(output_dir) unless File.exists? output_dir
        Frank.assets[:js].map { |name, group|
          new_file = File.join(Frank.export.path, Frank.assets[:package_path], name + '.js')
          puts " - \033[32mCreating\033[0m javascript #{new_file}" unless Frank.silent_export?
          f = File.new(new_file, 'wb')
          group[:paths].each { |file|
            file = file.sub(Frank.static_folder, '')
            source = File.join(Frank.export.path, file)
            if File.exists? source
              puts " - - \033[32mCompiling\033[0m javascript #{source}" unless Frank.silent_export?
              contents = read_binary_file(source)
              contents = YUI::JavaScriptCompressor.new.compress(contents) if Frank.compress?
              f.write(contents + "\n")
              File.unlink(source)
            end
          }
          f.close()
        }
      end

      def package_stylesheets
        return if Frank.assets == nil

        output_dir = File.join(Frank.export.path, Frank.assets[:package_path])
        Dir.mkdir(output_dir) unless File.exists? output_dir
        Frank.assets[:css].map { |name, group|
          new_file = File.join(Frank.export.path, Frank.assets[:package_path], name + '.css')
          puts " - \033[32mCreating\033[0m stylesheet '#{new_file}'" unless Frank.silent_export?
          f = File.new(new_file, 'wb')
          group[:paths].each { |file|
            file.sub!(Frank.static_folder, '')
            # Do a special trick for dynamic files
            file.sub!(Frank.dynamic_folder, '')
            file = file.chomp(File.extname(file)) + '.css'
            source = File.join(Frank.export.path, file)
            if File.exists? source
              puts " - - \033[32mCompiling\033[0m stylesheet '#{source}'" unless Frank.silent_export?
              contents = read_binary_file(source)
              contents = YUI::CssCompressor.new.compress(contents) if Frank.compress?
              f.write(contents + "\n")
              File.unlink(source)
            end
          }
          f.close()
        }
      end

      # ask the user if they want to overwrite the folder
      # get the input and return it
      def ask_nicely
        print "\033[31mA folder named `#{Frank.export.path}' already exists, overwrite it?\033[0m [y/n] "
        STDIN.gets.chomp.downcase
      end

      # verify that the user wants to overwrite the folder
      # remove it if so, exit if not
      def verify_overwriting
        overwrite = ask_nicely

        while overwrite.empty?
          overwrite = ask_nicely
        end

        overwrite == 'y' ? FileUtils.rm_rf(Frank.export.path) : exit
      end

      # TODO verbose everywhere is lame
      # create the dump dir, compile templates, copy over static assets
      def export!
        verify_overwriting if File.exist?(Frank.export.path)
        FileUtils.mkdir(Frank.export.path)

        unless Frank.silent_export?
          puts "\nFrank is..."
          puts " - \033[32mCreating\033[0m '#{Frank.export.path}'"
        end

        compile_templates
        copy_static
        if Frank.production?
          package_stylesheets
          package_javascripts
        end


        puts "\n \033[32mCongratulations, project dumped to '#{Frank.export.path}' successfully!\033[0m" unless Frank.silent_export?
      end
    end

  end
end
