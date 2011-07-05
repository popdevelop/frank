require 'frank/lorem'

module Frank
  module TemplateHelpers
    include FrankHelpers if defined? FrankHelpers

    def render_partial(path, *locals)
      pieces = path.split('/')
      partial = '_' + pieces.pop
      locals = locals.empty? ? nil : locals[0]
      render(File.join(pieces.join('/'), partial), partial = true, locals)
    end

    def read_binary_file(path)
      File.open(path, 'rb') {|f| f.read }
    end

    def javascript_include_tag(pack)
      "<script type=\"text/javascript\" src=\"#{pack}\"></script>"
    end

    def stylesheet_include_tag(pack)
      "<link href=\"#{pack}\" rel=\"stylesheet\" type=\"text/css\" />"
    end

    def include_templates(base)
      return if Frank.assets[:js]["templates"] == nil
      compiled = Frank.assets[:js]["templates"][:paths].flatten.map{ |path|
        if !File.directory? path
          contents  = read_binary_file(path)
          contents  = contents.gsub(/\r?\n/, "\\n").gsub("'", '\\\\\'')
          name = path.sub(File.join(Frank.dynamic_folder, base) + File::SEPARATOR, '').sub(Frank.assets[:template_extension],'')
          "#{Frank.assets[:template_namespace]}['#{name}'] = #{Frank.assets[:template_function]}('#{contents}')"
        end
      }
      ['<script type="text/javascript">',
       "#{Frank.assets[:template_namespace]} = #{Frank.assets[:template_namespace]} || {};",
       compiled,
       '</script>'].flatten.join("\n")
    end

    def include_javascripts(*packages)
      packages.map{ |pack|
        if Frank.production?
          File.join(Frank.assets[:package_path], pack.to_s + '.js')
        else
          Frank.assets[:js][pack.to_s][:urls] || {}
        end
      }.flatten.map{ |pack|
        javascript_include_tag pack
      }.join("\n")
    end

    def include_stylesheets(*packages)
      packages.map{ |pack|
        if Frank.production?
          File.join(Frank.assets[:package_path], pack.to_s + '.css')
        else
          Frank.assets[:css][pack.to_s][:urls] || {}
        end
      }.flatten.map{ |pack|
        # Replace extension with .css since frank will generate correct files
        file = pack.chomp(File.extname(pack)) + '.css'
        stylesheet_include_tag file
      }.join("\n")
    end

    def lorem
      Frank::Lorem.new
    end

    def refresh
      if Frank.exporting?
        nil
      else
        <<-JS
          <script type="text/javascript">
          (function(){
            var when = #{Time.now.to_i};

            function process( raw ){
              if( parseInt(raw) > when ) {
                window.location.reload();
              }
            }
            
            (function (){
              var req = (typeof XMLHttpRequest !== "undefined") ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
              req.onreadystatechange = function (aEvt) {
                if ( req.readyState === 4 ) {
                  process( req.responseText );
                }
              };
              req.open('GET', '/__refresh__', true);
              req.send( null );
              setTimeout( arguments.callee, 1000 );
            })();

          })();
          </script>
        JS
      end
    end

  end
end
