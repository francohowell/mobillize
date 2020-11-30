if [ -x "$(command -v sidekiqctl)" ]; then

    echo "Removing Sidekiq Processes"

    ps -ef | grep sidekiq | grep busy | grep -v grep | awk '{print $2}'  > sidekiq.pid

    sidekiqctl quiet sidekiq.pid -t 60

    sleep 30 

    sidekiqctl stop sidekiq.pid -t 60

fi

if ! [ -z "$(ls -A /home/ubuntu/mobilize-sidekiq/)" ]; then
    sudo rm -r /home/ubuntu/mobilize-sidekiq/*
fi