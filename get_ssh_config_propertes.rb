require 'yaml'
require 'pp'
require 'optparse'

options = {}
# compact notation. TODO: diversify
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'
  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end
  opts.on('-oFILE', '--out=FILE', 'Generate the propertied file FILE') do |data|
    options[:out_file] = data
  end
  opts.on('-dDIR', '--dir=DIR', 'Change to the DIR directory before running Vagrant command. The current directory matters for Vagrant') do |data|
    options[:out_file] = data
  end
end.parse!
# 
raw_response = %x|vagrant ssh-config| #  automatically does .stdout
ssh_config = YAML.parse( raw_response)
pp ssh_config
# pp ssh_config[ssh_config.keys[0]]
