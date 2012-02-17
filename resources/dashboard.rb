def initialize(*args)
  super
  @action = :create
end

actions :create, :delete

attribute :slug, :name_attribute => true
attribute :title, :kind_of => String, :required => true
