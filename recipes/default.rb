#
# Cookbook Name:: cloudwatch-agent-cookbook
# Recipe:: default
#
# Copyright (c) 2015 Congenia Integracion

# both the template and the setup script download call the installation procedure because there might be changes
# in the logs configuration when the agent is already installed; the bash resource will only be called once anyway

logs = node[:congenia_common][:cloudwatch][:logs]
if node['opsworks']['layers']['php-app']
  node['deploy'].each do |app|
    ["#{app}-access.log", "#{app}-error.log"].each do |logfile|
      logs << {"log_location" => "/var/log/apache2/#{logfile}", "log_group_name" => node['opsworks']['stack']['name'], "log_stream_name" => logfile, "datetime_format" => "%b %d %H:%M:%S %Y"},
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
