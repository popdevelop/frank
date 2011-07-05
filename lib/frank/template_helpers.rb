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
      '<script type="text/javascript" src="' + pack + '"></script>'
    end

    def include_templates(base)
      return if Frank.assets[:js]["templates"] == nil
      compiled = Frank.assets[:js]["templates"][:paths].flatten.map{ |path|
        if !File.directory? path
          contents  = read_binary_file(path)
          contents  = contents.gsub(/\r?\n/, "\\n").gsub("'", '\\\\\'')
          name = path.sub(File.join(Frank.dynamic_folder, base) + '/', '').sub('.'+base,'')
          "window.JST['#{name}'] = _.template('#{contents}')"
        end
      }
      ['<script type="text/javascript">', 'window.JST = window.JST || {};', compiled, '</script>'].flatten.join("\n")
    end

    def include_javascripts(*packages)
      packages.map{ |pack|
        Frank.production? ? pack.to_s + '.js' : Frank.assets[:js][pack.to_s][:urls] || {}
      }.flatten.map{ |pack|
        javascript_include_tag pack
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
