action :create do
  graph = Graphiti::Graph.new( :title => new_resource.title,
                               :default_options => new_resource.default_options,
                               :type => new_resource.type,
                               :node => new_resource.remote_node)

  new_resource.dashboards.each do |slug|
    graph.add_to_dashboard(slug)
  end

  new_resource.updated_by_last_action(true) if graph
end
