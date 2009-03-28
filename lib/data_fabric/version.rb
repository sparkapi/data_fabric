require 'yaml'

module DataFabric
  module Version
    STRING = begin
      data = YAML.load(File.read(File.dirname(__FILE__) << "/../../VERSION.yml"))
      "#{data[:major]}.#{data[:minor]}.#{data[:patch]}"
    end
  end
end
