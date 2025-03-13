ENV.fetch('PLUGINS', '').split(':').each do |plugin|
  plugin_gem,*args = plugin.split(',')
  gem plugin_gem, *args
end
