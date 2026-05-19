#!/bin/bash
# Create an endless loop for running the main Eagle executable
# and the updater script. The main  executable will run followed
# by the updater again in and endless loop in the event that a
# firmware update was done.

counter=0

while [[ 1 ]]; do
	# Run the main executable
	./eagle

	retval=$?

	echo "Eagle exited with status ${retval}"

	# If the eagle app exited with code 1 then
	# we have a pending update to process
	if [[ $retval = 1 ]]; then
		# Read the filename for the new firmware
		# from the textfile
		read -r filename < firmwareVersion.txt
		
		# Unzip the downloaded zip file
		unzip $filename
		
		# Make the updater script executable
		sudo chmod +x updater.sh

		# Run the updater script
		./updater.sh

		if [[ "$?" = 0 ]]; then
			echo "Firmware updated successfully. Rebooting."
			rm updater.sh
			rm $filename
			rm eagleHash.txt
			rm firmwareVersion.txt
			reboot

		else
			echo "Firmware update failed. Reverting to previous firmware."
			rm updater.sh
			rm $filename
			rm eagleHash.txt
			rm firmwareVersion.txt
		fi

		counter=0

	# If it exited with code 2 then we have
	# a pending shutdown request from the iOS app
	elif [[ $retval = 2 ]]; then
		shutdown -P now

	# If it exited with code 4 then we
	# have a pending reboot request
	elif [[ $retval = 4 ]]; then
		reboot

	# If it exited with code 8 then we have a
	# pending shutdown request from E6 turning off
	elif [[ $retval = 8 ]]; then
		shutdown -P now

	# If it exited with code 16 then we received
	# a request to restart the app
	elif [[ $retval = 16 ]]; then
		counter=0
		continue

	elif [[ $retval = 32 ]]; then
		counter=0
		continue

	else
		counter=$((counter+1))

		if [[ $counter = 3 ]]; then
			# Use the wall command to send a system
			# message to every open terminal in the
			# system before rebooting after a 5 minute delay
			wall "Error encountered. Rebooting in 5 minutes."
			delay 300
			reboot
		fi

		continue
	fi
done
