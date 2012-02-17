def initialize(*args)
  super
  @action = :create
end

actions :create

attribute :title, :name_attribute => true, :kind_of => String
attribute :type, :required => true, :kind_of => String
attribute :default_options, :required => true, :kind_of => Hash
attribute :dashboards, :required => false, :kind_of => Array
attribute :remote_node, :required => true, :kind_of => Chef::Node
