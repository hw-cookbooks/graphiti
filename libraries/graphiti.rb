#
# Cookbook Name:: graphite
# Library:: graphiti
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

require "rest_client"
require "cgi"
require "json"

# Monkey patches stolen from Sensu

class Hash
  def deep_diff(hash)
    (self.keys | hash.keys).inject(Hash.new) do |diff, key|
      unless self[key] == hash[key]
        if self[key].is_a?(Hash) && hash[key].is_a?(Hash)
          diff[key] = self[key].deep_diff(hash[key])
        else
          diff[key] = [self[key], hash[key]]
        end
      end
      diff
    end
  end

  def deep_merge(other_hash, &merger)
    merger ||= proc do |key, oldval, newval|
      oldval.deep_merge(newval, &merger) rescue newval
    end
    merge(other_hash, &merger)
  end
end

module Graphiti

  class Common

    def self.resource
      @@resource ||= RestClient::Resource.new("http://127.0.0.1:8081")
    end

  end # Common

  class Dashboard < Common

    class << self
      def all
        JSON.parse(resource["dashboards.js"].get)
      end

      def get!(slug)
        if resource["dashboards"]["#{slug}.js"].get == "null"
          raise RestClient::ResourceNotFound
        end
      end

      def exists?(slug)
        !begin
           dashboard = resource["dashboards"]["#{slug}.js"].get

           if dashboard == "null"
             raise RestClient::ResourceNotFound
           else
             !!dashboard
           end
         rescue RestClient::ResourceNotFound
           nil
         end.nil?
      end

      def create(options = {})
        raise ArgumentError.new("Must pass a hash") unless options.respond_to? :has_key?
        raise ArgumentError unless options.has_key? :slug
        raise ArgumentError unless options.has_key? :title

        unless exists? options[:slug]
          resource["dashboards"].post :dashboard => options
        end
      end

      def update(slug, options = {})
        raise ArgumentError unless options.has_key? :slug
        raise ArgumentError unless options.has_key? :title

        if exists? options[:slug]
          puts resource["dashboards"]["#{options[:slug]}.js"].put :dashboard => options
        end
      end

      def delete(slug)
        puts "exists? slug: #{slug} #{exists?(slug)}"
        raise ArgumentError.new("#{slug} does not exist, not deleting") unless exists? slug

        puts resource["dashboards"]["#{slug}.js"].delete
      end
    end

  end # Dashboard

  class Graph < Common

    %w[uri json].each do |lib|
      require lib
    end

    attr_reader( :title,
                 :json,
                 :url,
                 :default_options,
                 :type,
                 :node,
                 :remote_graph,
                 :uuid )

    def initialize(options = {})
      @title ||= options[:title]
      @default_options ||= options[:default_options]
      @type ||= options[:type]
      @node ||= options[:node]
      @remote_graph = exists?

      response = save
      @uuid = response["uuid"]
      Chef::Log.info "#{self}#initialize: saved graph #{uuid} response: #{response.inspect}"
      uuid
    end

    def save
      if remote_graph and remote_graph.has_key? "uuid"
        uuid = remote_graph["uuid"]
        Chef::Log.debug "#{self}#save: graph exists for #{title} #{uuid}, updating"
        Chef::Log.debug "#{self}#save: diff: #{graph.deep_diff(remote_graph).inspect}"

        response = resource["graphs"][uuid].put :uuid => uuid, :graph => graph.deep_merge(remote_graph)

        JSON.parse(response)
      else
        Chef::Log.debug "#{self}#save: creating graph: #{graph.inspect}"

        response = resource["graphs"].post :graph => graph

        JSON.parse(response)
      end
    end

    def dashboards
      resource["graphs"]["dashboards"]
    end

    def add_to_dashboard slug
      r = dashboards.post :dashboard => slug, :uuid => uuid
      Chef::Log.debug "#{self}#add_to_dashboard: response #{r}"
    end

    def remove_from_dashboard slug
      r = dashboards.delete :dashboard => slug, :uuid => uuid
      Chef::Log.debug "#{self}#remove_to_dashboard: response #{r}"
    end


    def graph
      {
        "title" => title,
        "url" => url,
        "json" => JSON.pretty_generate(targets_and_options)
      }
    end

    def targets_and_options
      unless Template.graphs(node).has_key? type
        raise StandardError.new("#{self}#targets: no template defined for #{type}")
      else
        Template.graph_for(type, default_options, node)
      end
    end


    def urlbase
      "http://graphite/render/?"
    end

    def encode_www_form enum
      enum.collect do |k, v|
        "#{k.to_s}=#{CGI::escape(v.to_s)}"
      end.join('&')
    end

    def form
      targets_and_options.deep_merge("_timestamp_" => Time.now.to_i * 1000).to_a
    end

    def url
      urlbase << encode_www_form(form) << "#.png"
    end

    def exists?
      response = resource["graphs.js"].get
      graphs = JSON.parse(response)
      graphs["graphs"].detect do |graph|
        graph["title"] == title
      end
    end

    def resource
      @@resource ||= RestClient::Resource.new("http://127.0.0.1:8081")
    end

  end # Graph

  class Template
    class << self
      def name(node)
        node.name.gsub(".", "_")
      end

      # TODO: extract targets and options into params on the r/p
      def graphs(n)
        {
          "cpu" =>
          "groupByNode(collectd.#{name(n)}.cpu.*.cpu.*.value, 5, 'sumSeries')",

          "memory" =>
          "groupByNode(collectd.#{name(n)}.memory.memory.*.value,4,'sumSeries')",

          "interface_if_octets_rx" =>
          "groupByNode(collectd.#{name(n)}.interface.if_octets.*.rx,4,'sumSeries')",

          "interface_if_octets_tx" =>
          "groupByNode(collectd.#{name(n)}.interface.if_octets.*.tx,4,'sumSeries')",

          "qmail_filecount_files" =>
          "groupByNode(collectd.#{name(n)}.filecount.*.files.value,3,'sumSeries')",

          "qmail_filecount_files_stacked" =>
          "groupByNode(collectd.*.filecount.*.files.value,1,'sumSeries')",

          "qmail_filecount_files_derivative" =>
          "groupByNode(collectd.#{name(n)}.filecount.*.files.value,3,'derivative')",

          "qmail_filecount_files_derivative_stacked" =>
          "groupByNode(collectd.*.filecount.*.files.value,1,'derivative')",

          "qmail_filecount_files_integral" =>
          "groupByNode(collectd.#{name(n)}.filecount.*.files.value,3,'integral')",

          "qmail_filecount_files_integral_stacked" =>
          "groupByNode(collectd.*.filecount.*.files.value,1,'integral')",

          "qmail_filecount_size" =>
          "groupByNode(collectd.#{name(n)}.filecount.*.bytes.value,3,'sumSeries')",

          "qmail_filecount_size_stacked" =>
          "groupByNode(collectd.*.filecount.*.bytes.value,1,'sumSeries')"
        }
      end

      def graph_for type, default_options, node = nil
        {
          "options" => default_options,
          "targets" =>
          [
           [
            graphs(node)[type],
            {}
           ]
          ]
        }
      end

    end
  end
end
