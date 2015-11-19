#
# Cookbook Name:: cloudwatch-agent-cookbook
# Recipe:: default
#
# Copyright (c) 2015 Congenia Integracion

# both the template and the setup script download call the installation procedure because there might be changes
# in the logs configuration when the agent is already installed; the bash resource will only be called once anyway

template "/etc/awslogs.conf" do
  source "awslogs.conf.erb"
  owner 'root'
  group 'root'
  mode 0600
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
  code "python /root/awslogs-agent-setup.py --non-interactive --region=#{node[:congenia_mail][:aws_region]} --configfile=/etc/awslogs.conf"
end

