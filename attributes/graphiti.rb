default.graphiti.dependencies = %w(libcurl4-gnutls-dev)
default.graphiti.tarfile = '/usr/src/graphiti.tgz'
default.graphiti.url = 'https://github.com/paperlesspost/graphiti/archive/master.tar.gz'
default.graphiti.base = '/srv/graphiti'
default.graphiti.graphite_base_url = 'http://127.0.0.1'
default.graphiti.redis_url = 'localhost:6379:1/graphiti'
default.graphiti.tmp_dir = '/srv/graphiti/tmp'
default.graphiti.auto_refresh.enabled = true
default.graphiti.auto_refresh.interval = 60
default.graphiti.rack_env = node.chef_environment
default.graphiti.metric_prefix = 'collectd'
default.graphiti.default_metrics = %w(carbon.agents.*.metricsReceived)
default.graphiti.unicorn.timeout = 60
default.graphiti.unicorn.cow_friendly = true
default.graphiti.s3_bucket = 'graphiti'
default.graphiti.port = 8081

default.graphiti.default_options = {
  'title' => 'New Graph',
  'from' => '-6h',
  'font' => 'DroidSans',
  'fontSize' => 10,
  'thickness' => 2,
  'bgcolor' => '#FFFFFF',
  'fgcolor' => '#333333',
  'majorGridLineColor' => '#ADADAD',
  'minorGridLineColor' => '#E5E5E5',
  'hideLegend' => false,
  'areaMode' => 'stacked',
}

default.graphiti.graph_types = []
