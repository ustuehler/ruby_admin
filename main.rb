require 'optparse'

options = {}

opts = OptionParser.new do |opts|
  opts.on '--help' do
    puts "pee off!"
    exit 2
  end
end

opts.parse!
