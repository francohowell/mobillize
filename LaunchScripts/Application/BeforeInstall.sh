sudo service nginx stop


if ! [ -z "$(ls -A /var/www/mus-rails/)" ]; then
    sudo rm -r /var/www/mus-rails/*
fi