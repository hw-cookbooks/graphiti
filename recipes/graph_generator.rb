#
# Cookbook Name:: graphite
# Recipe:: graph_generator
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

nodes = search(:node, "graphiti_graph_types:*")

nodes.map do |remote_node|

  [remote_node.graphiti.graph_types].flatten.compact.each do |graph_type|

    dashboards = {
      # Graph for all nodes for this graph type
      graph_type => "all #{graph_type}",
      # Dashboard for just this node, containing all graphs for the node
      remote_node.name => remote_node.fqdn,
      # Dashboard for just this node AND this graph, containing ONLY
      # this graph type
      "#{remote_node.name}_#{graph_type}" => "#{remote_node.fqdn} #{graph_type}"
    }

    dashboards.each do |slug, title|
      graphiti_dashboard slug do
        title title
      end
    end

    # TODO: Need to make this like targets (templated)
    # then we'll be able to pass along from/to, diff colors, etc.

    options = {
      "title" => "#{remote_node.fqdn} #{graph_type}"
    }

    options = node.graphiti.default_options.to_hash.deep_merge(options)

    graphiti_graph options["title"] do
      type graph_type
      default_options options
      dashboards dashboards.keys
      remote_node remote_node
    end
  end

end

{ "quarterly" => "-15minutes",
  "hourly" => "-1hour",
  "daily" => "-1d" }.each do |slug,from|

  dashboard = "qmail_#{slug}"
  graphiti_dashboard dashboard do
    title "qmail #{slug}"
  end

  [ "qmail_filecount_files_stacked",
    "qmail_filecount_files_derivative_stacked",
    "qmail_filecount_files_integral_stacked",
    "qmail_filecount_size_stacked",
  ].each do |title|

    options = {
      "title" => "#{title.gsub("_", " ")} #{slug}",
      "from" => from,
      "areaMode" => case title
                    when /derivative/
                      ""
                    else
                      "stacked"
                    end
    }

    options = node.graphiti.default_options.to_hash.deep_merge(options)

    graphiti_graph "#{title}_#{from}" do
      type title
      default_options options
      dashboards [ dashboard ]
      remote_node node
    end
  end
end
