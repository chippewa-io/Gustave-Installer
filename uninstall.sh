#!/bin/bash
################################################################################
#Setup
removed_items="The following items have been removed from your system successfully:"

#check if being run by sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi


################################################################################
# Stop the service
echo "Stopping Gustave service..."
sudo systemctl stop gustave.service
if [ $? -eq 0 ]
then
    echo "Gustave service stopped successfully."
    removed_items+="\n - Gustave service: /etc/systemd/system/gustave.service"
else
    echo "Gustave service failed to stop."
    exit 2
fi

################################################################################
# Check to see if the service is running
if pgrep -x "gustave" > /dev/null
then
    echo "Gustave is still running after an attempt to stop it.  Please manually stop the service before uninstalling."
    exit 3
fi


################################################################################
# Disable the service so it doesn't start on boot
sudo systemctl disable gustave
if [ $? -eq 0 ]
then
    echo "Gustave service disabled successfully."
else
    echo "Gustave service failed to disable."
    exit 4
fi


################################################################################
# Reload the systemd daemon to recognize the service removal
sudo systemctl daemon-reload
if [ $? -eq 0 ]
then
    echo "Systemd daemon reloaded successfully."
else
    echo "Systemd daemon failed to reload."
    exit 5
fi

################################################################################
# Remove the gustave executable
sudo rm /usr/local/bin/gustave
if [ $? -eq 0 ]
then
    echo "Gustave executable removed successfully."
    removed_items+="\n - Gustave executable: /usr/local/bin/gustave"
else
    echo "Gustave executable failed to remove."
    exit 6
fi


################################################################################
#Ask user if they'd like to remove MySQL database and user
read -p "Would you like to remove the MySQL database and user also? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mysql_removal=true
    else
    mysql_removal=false
fi

# Get database credentials from config file
if [ $mysql_removal == true ]
then
    if [ ! -f /etc/gustave/config.py ]
    then
        echo "Config file not found.  Please remove the database manually."
        exit 7
    fi
    MYSQL_DATABASE_USER=$(python3 -c "from config import Config; print(Config.MYSQL_DATABASE_USER)")
    MYSQL_DATABASE_PASSWORD=$(python3 -c "from config import Config; print(Config.MYSQL_DATABASE_PASSWORD)")
    MYSQL_DATABASE_DB=$(python3 -c "from config import Config; print(Config.MYSQL_DATABASE_DB)")
    MYSQL_DATABASE_HOST=$(python3 -c "from config import Config; print(Config.MYSQL_DATABASE_HOST)")
#check if the datbase is localhost or 127.0.0.1
    if [ "$MYSQL_DATABASE_HOST" == "localhost" ] || [ "$MYSQL_DATABASE_HOST" == "127.0.0.1" ]
    then
      MYSQL_DATABASE_HOST=""
      echo "Warning! \n  This will fully delete the database and user from the local MySQL server."
      read -p "Are you sure you want to continue? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Nn]$ ]]
      then
          echo "Database removal aborted."
          exit 0
      fi
      sudo mysql -u root -e "DROP DATABASE $MYSQL_DATABASE_DB;"
        if [ $? -eq 0 ]
        then
            echo "Database removed successfully."
            removed_items+="\n - MySQL database: $MYSQL_DATABASE_DB"
        else
            echo "Database failed to remove."
            exit 8
        fi
      sudo mysql -u root -e "DROP USER '$MYSQL_DATABASE_USER'@'localhost';"
        if [ $? -eq 0 ]
        then
            echo "User removed successfully."
            removed_items+="\n - MySQL user: $MYSQL_DATABASE_USER"
        else
            echo "User failed to remove."
            exit 9
        fi
      else
      echo -e "Database is on a remote host.  Please remove the database manually.  It's details are as follows: \n Remote Host: $MYSQL_DATABASE_HOST \n Database: $MYSQL_DATABASE_DB \n Username: $MYSQL_DATABASE_USER \n Password: $MYSQL_DATABASE_PASSWORD"
    fi
fi

################################################################################
# Remove the gustave directory and config file
sudo rm -r /etc/gustave
if [ $? -eq 0 ]
then
    echo "Gustave directory removed successfully."
    removed_items+="\n - Gustave directory: /etc/gustave"
else
    echo "Gustave directory failed to remove."
    exit 10
fi
################################################################################
# Remove the gustave user
sudo deluser --system gustave
if [ $? -eq 0 ]
then
    echo "Gustave user removed successfully."
    removed_items+="\n - Gustave user: gustave"
else
    echo "Gustave user failed to remove."
    exit 11
fi

read -p "Would you like to remove python3-apt? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo apt remove -y python3-apt
    if [ $? -eq 0 ]
    then
        echo "python3-apt removed successfully."
        removed_items+="\n - python3-apt"
    else
        echo "python3-apt failed to remove."
        exit 12
    fi
    else
    python3-apt=false
fi

read -p "Would you like to remove dialog? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo apt remove -y dialog
    if [ $? -eq 0 ]
    then
        echo "dialog removed successfully."
        removed_items+="\n - dialog"
    else
        echo "dialog failed to remove."
        exit 13
    fi
    else
    dialog=false
fi

read -p "Would you like to remove jq? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo apt remove -y jq
    if [ $? -eq 0 ]
    then
        echo "jq removed successfully."
        removed_items+="\n - jq"
    else
        echo "jq failed to remove."
        exit 14
    fi
    else
    jq=false
fi
################################################################################
#Finish!
echo "Uninstallation complete!"
echo -e $removed_items
