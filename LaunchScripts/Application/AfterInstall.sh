#sudo chown -R $(whoami):$(whoami) /home/ubuntu/mobilize-sidekiq

cd /var/www/mus-rails

sudo cp /home/ubuntu/master.key /var/www/mus-rails/config

sudo cp LaunchScripts/Application/nginx.conf /opt/nginx/conf

#/home/ubuntu/.rvm/gems/ruby-2.7.0/wrappers/bundle install
/usr/local/bin/bundle install

RAILS_ENV=production /usr/bin/rake db:migrate

RAILS_ENV=production /usr/bin/rake assets:precompile

sudo chown -R ubuntu:ubuntu /var/www/mus-rails

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json