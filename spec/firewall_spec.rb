require 'chefspec'

describe 'graphiti::firewall' do
  let(:chef_run) { ChefSpec::ChefRunner.new.converge 'graphiti::firewall' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
