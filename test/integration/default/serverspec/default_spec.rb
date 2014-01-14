require 'serverspec'
require 'net/http'
require 'uri'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe 'Graphiti' do
  it 'returns a reponse' do
    uri = URI('http://localhost:8081')
    response = Net::HTTP.get_response(uri)
    response.code.should eq('200')
    expect(response.body).to match(/graphiti/i)
  end
end
