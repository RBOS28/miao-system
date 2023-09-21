# miao-system
router with security function

Hi, this is the message from the author.

So you will need to first run the shell by using the command

command = sudo ./setup-router.sh

after that you have to restart the your machine 

command = sudo reboot

after that using the command to check whether you got the right track or not.

command = sudo iptables -t nat -L -v -n

if everything all right, you will getting something like how many packet and how many bytes, if you got the 0 packet and 0 bytes, means you are wrong.
So you may contact me if you feel that you have any problem.

-----------------------------------------------------------------------------------------------------------------------------------------------------

after that we proceed to the capture-machine to capture the normal log. 

and then we will have to run it, by using the 

command = bash capture-machine.sh

after that you will have to relaod something or search something for the device that connected to the router. so that the tcpdump and tshark will be more efficiency for capture the traffic or the network log

so you can open the files of it by using the

command = sudo vim /$HOME/miao-system/csv_files/wlan0_traffic

and then you can see the result of the csv file, and you may proceed for the abnormal traffic now
