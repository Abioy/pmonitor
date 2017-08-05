cd /home/abioy/local/heater

bash clean.sh

echo `date` >> log/heater.log
bash pull.sh smzdm.sh >> log/heater.log

sleep 1

( cd /home/abioy/local/heater; flock -n log/run.lock bash smzdm.sh >> log/heater.log 2>&1 & )
