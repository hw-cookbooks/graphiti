require 'chefspec'

describe 'graphiti::default' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'graphiti::default' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
