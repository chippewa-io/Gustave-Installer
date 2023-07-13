#!/bin/bash
#Check to see if our configuration profile has been deployed
if [ -f /Library/Managed\ Preferences/io.chippewa.gustave.plist ]; then
    echo "Configuration profile is installed"
else
    echo "Configuration profile is not installed.  Please deploy the gustave configuration profile before deploying the binary to your clients."
    exit 1
fi

#Check to see if the gustave binary is installed
if [ -f /usr/local/bin/gustave ]; then
    echo "Gustave binary is installed"
else
    echo "Gustave binary is not installed"
    exit 2
fi

#Initiatlize Gustave
sudo /usr/local/bin/gustave initiate
if [ $? -eq 0 ]; then
    echo "Gustave initiated successfully"
else
    echo "Gustave failed to initiate.  Check to ensure your clients are able to reach your gustave server at it's configured address: \n $(defaults read /Library/Managed\ Preferences/io.chippewa.gustave.plist server_url)"
    #Check to see if we can ping the URL configured in the config file
    ping -c 1 $(defaults read /Library/Managed\ Preferences/io.chippewa.gustave.plist server_url)
    if [ $? -eq 0 ]; then
        echo "Your clients are able to reach your gustave server at $(defaults read /Library/Managed\ Preferences/io.chippewa.gustave.plist server_url)"
        echo "Trying to intitialize again..."
        sudo /usr/local/bin/gustave initiate
        if [ $? -eq 0 ]; then
            echo "Gustave initiated successfully"
        else
            echo "Gustave failed to initiate.  Check to ensure your clients are able to reach your gustave server at it's configured address: \n $(defaults read /Library/Managed\ Preferences/io.chippewa.gustave.plist server_url)"
            exit 3
        fi
    else
        echo "Your clients are unable to reach your gustave server at $(defaults read /Library/Managed\ Preferences/io.chippewa.gustave.plist server_url)"
    fi
    exit 3
fi

