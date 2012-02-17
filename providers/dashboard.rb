action :create do
  dashboard = Graphiti::Dashboard.create( :slug => new_resource.slug,
                                          :title => new_resource.title )

  new_resource.updated_by_last_action(true) if dashboard
end

action :delete do
  new_resource.updated_by_last_action(true) if
    Graphiti::Dashboard.delete(new_resource.slug)
end
