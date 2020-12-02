sudo service nginx start

cd /var/www/mus-rails

/usr/local/bin/bundle exec sidekiq -e production -d -L /home/ubuntu/sidekiq.log
