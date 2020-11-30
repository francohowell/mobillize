#sudo chown -R $(whoami):$(whoami) /home/ubuntu/mobilize-sidekiq

cd /home/ubuntu/mobilize-sidekiq

/home/ubuntu/.rvm/gems/ruby-2.7.0/wrappers/bundle install

cp /home/ubuntu/master.key /home/ubuntu/mobilize-sidekiq/config
