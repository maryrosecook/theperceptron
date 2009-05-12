module Configuring
  
  def self.get(identifier)
    config = YAML::load(File.open("config/config.yml"))
    return config[identifier]
  end
end