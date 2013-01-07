name             "graphiti"
maintainer       "Heavy Water Software Inc."
maintainer_email "ops@hw-ops.com"
license          "Apache 2.0"
description      "Installs/Configures graphiti"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

%w{build-essential iptables runit}.each do |d|
  depends d
end

%w{ubuntu debian fedora amazon}.each do |os|
  supports os
end
