echo 'checking for existing installation...'
DATE=`date +%Y-%m-%d`
echo "moving existing /opt/cif to /opt/cif.old-$DATE"
mv /opt/cif /opt/cif-$DATE

echo 'shutting down cif-services'

service monit stop
service cif-smrt stop
service cif-worker stop
service cif-starman stop
service cif-router stop

echo 'waiting to make sure things stopped'
sleep 2
SERVICES=`ps aux | grep cif | grep -v grep | awk -F' ' '{ print $2 }'`

for S in $SERVICES
do
	echo "forcefully killing: $S"
	kill -KILL $S
done