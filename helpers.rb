module FrankHelpers
  def render_jst(template)
    filename = File.join(Frank.root, Frank.dynamic_folder,
                         'jst', template.sub('/', '-')) + '.jst'
    content = File.open(filename).read().gsub(/'/, " \\\\'").gsub(/$/, ' \\')
    "JST = window.JST || {};\nJST['#{template}'] = " +
      "_.template(' \\\n#{content.chop}');"
  end
end
