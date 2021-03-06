#
# Cookbook Name:: cloudwatch-agent-cookbook
# Recipe:: default
#
# Copyright (c) 2015 Congenia Integracion

# both the template and the setup script download call the installation procedure because there might be changes
# in the logs configuration when the agent is already installed; the bash resource will only be called once anyway

logs = []
if node[:congenia_common][:cloudwatch] and node[:congenia_common][:cloudwatch][:logs] and !node[:congenia_common][:cloudwatch][:logs].empty?
  node[:congenia_common][:cloudwatch][:logs].each do |log|
    logs << log.clone
  end
end

#logs = node[:congenia_common][:cloudwatch][:logs].clone
if node[:opsworks] and node[:opsworks][:layers].has_key?("php-app")
  node[:deploy].keys.each do |app|
    app_name = app['name']
    ["#{app}-access.log", "#{app}-ssl-access.log", "#{app}-error.log"].each do |logfile|
      logs << {:log_location => "/var/log/apache2/#{logfile}", :log_group_name => node[:opsworks][:stack][:name], :log_stream_name => logfile, :datetime_format => "%d/%b/%Y:%H:%M:%S %z"}
    end
  end
end

template "/etc/awslogs.conf" do
  source "awslogs.conf.erb"
  owner 'root'
  group 'root'
  mode 0600
  variables :logs => logs
  notifies :create, 'remote_file[/root/awslogs-agent-setup.py]'
  notifies :run, 'bash[install_awslogs-agent]'
end

remote_file '/root/awslogs-agent-setup.py' do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  notifies :run, 'bash[install_awslogs-agent]'
  action :nothing
end

bash 'install_awslogs-agent' do
  action :nothing
  code "python /root/awslogs-agent-setup.py --non-interactive --region=eu-west-1 --configfile=/etc/awslogs.conf"
end
