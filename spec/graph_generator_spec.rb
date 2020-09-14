require 'chefspec'

describe 'graphiti::graph_generator' do
  let(:chef_run) { ChefSpec::ChefRunner.new.converge 'graphiti::graph_generator' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
