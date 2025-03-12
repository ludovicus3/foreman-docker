unless ENV['PLUGINS'].empty?
  ENV['PLUGINS'].split(':').each do |plugin|
    plugin_gem,*args = plugin.split(',')
    gem plugin_gem, *args
  end
end

source = ENV['PROJECT_SOURCE']
unless source.nil? or source.empty?
  Dir.glob(File.join(source, '**', '*.gemspec')) do |file|
    spec = Gem::Specification.load(file)
    gem spec.name, path: File.dirname(file)
  end
end