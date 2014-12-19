( cd /home/abioy/local/heater; echo `date` >> log/heater.log ; flock -n log/run.lock bash smzdm.sh >> log/heater.log 2>&1 & )

cd /home/abioy/local/heater
bash pull.sh smzdm.sh >> log/heater.log
