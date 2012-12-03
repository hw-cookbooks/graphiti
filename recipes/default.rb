#
# Cookbook Name:: graphiti
# Recipe:: default
#
# Copyright 2012, AJ Christensen <aj@junglist.gen.nz>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "build-essential"

user node['graphiti']['user'] do
  comment "Graphiti Graphite Dashboard"
  action :create
end

case node['platform_family']
when "debian"
  %w[libcurl4-gnutls-dev ruby1.9.1-full].each do |pkg|
    package pkg do
      action :install
    end
  end
  gem_package "bundler"

when "fedora"
  %w{ruby ruby-devel rubygem-bundler rubygem-daemons rubygem-rack rubygem-rake rubygem-sinatra rubygem-haml libcurl-devel}.each do |pkg|
    package pkg do
      action :install
    end
  end

end

remote_file node['graphiti']['tarfile'] do
  mode "00666"
  owner node['graphiti']['user']
  group node['graphiti']['user']
  source node['graphiti']['url']
  action :create_if_missing
end

directory node['graphiti']['base'] do
  owner node['graphiti']['user']
  group node['graphiti']['user']
end

directory File.join(node.graphiti.base, "log") do
  owner node['graphiti']['user']
  group node['graphiti']['user']
end

execute "bundle" do
  command "bundle install --deployment --binstubs; " +
    "bundle exec rake graphiti:metrics"

  cwd node['graphiti']['base']
  action :nothing
end

cron "graphiti:metrics" do
  minute "*/15"
  command "cd #{node['graphiti']['base']} && bundle exec rake graphiti:metrics"
  user node['graphiti']['user']
end

execute "graphiti: untar" do
  command "tar zxf #{node['graphiti']['tarfile']} -C #{node['graphiti']['base']} --strip-components=1"
  creates File.join(node['graphiti']['base'], "Rakefile")
  user node['graphiti']['user']
  group node['graphiti']['user']
  notifies :run, resources(:execute => "bundle"), :immediately
end

# XXX domain-specific stuff. Not everyone has their databags set up like this
# (nor does everyone want graph storage in S3 as a feature)
#aws = data_bag_item "aws", node.chef_environment
#template File.join(node.graphiti.base, "config", "amazon_s3.yml") do
#  variables :hash => { node.chef_environment => {
#      "bucket" => node.graphiti.s3_bucket,
#      "access_key_id" => aws["aws_access_key_id"],
#      "secret_access_key" => aws["aws_secret_access_key"]
#    } }
#  owner node['graphiti']['user']
#  group node['graphiti']['user']
#  notifies :restart, "service[graphiti]"
#end

template File.join(node.graphiti.base, "config", "settings.yml") do
  owner node['graphiti']['user']
  group node['graphiti']['user']
  variables :hash => {
    "graphite_host" => node['graphiti']['graphite_host'],
    "redis_url" => node['graphiti']['redis_url'],
    "tmp_dir" => node['graphiti']['tmp_dir'],
    "fonts" => %w[DroidSans DejaVuSans],
    "metric_prefix" => node['graphiti']['metric_prefix'],
    "default_options" => node['graphiti']['default_options'].to_hash,
    "default_metrics" => node['graphiti']['default_metrics'].to_a,
  }
  notifies :restart, "service[graphiti]"
end

directory "/var/run/unicorn" do
  owner node['graphiti']['user']
  group node['graphiti']['user']
end

template File.join(node['graphiti']['base'], "config", "unicorn.rb") do
  owner node['graphiti']['user']
  group node['graphiti']['user']
  variables( :worker_processes => node['cpu']['total'],
             :timeout => node['graphiti']['unicorn']['timeout'],
             :cow_friendly => node['graphiti']['unicorn']['cow_friendly'] )
  notifies :restart, "service[graphiti]"
end

case node['platform_family']
when "debian"
  runit_service "graphiti"
when "fedora"
  # XXX still need to write init script
  service "graphiti" do
    action [ :enable, :start ]
  end
end
