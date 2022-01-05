#!/bin/bash

#Install packages:

#cant install all these with root
#better to avoid the pain in the ass

if [[ $EUID -ne 0 ]]
  then

  echo 'Run as root!'
  echo 'Executing (sudo su)' && sudo su

fi

apt update

#print echo
ecco () {
  i=0
  while [ $i -lt $1 ]
    do
    echo
    ((i++))
  done
}

check_pack () {

  if [[ $? -ne 0 ]]
    then
    ecco 2
    echo "Couldn't install $1"
    ecco 1
    sleep 1
    echo 'Trying to add PPA...'
    ecco 1

    if [[ "$1" == "curl" ]]
      then
      
      apt install add-apt-repository -y

      if [[ $? -ne 0 ]]
         then
         ecco 1
         apt install -y software-properties-common
         
         if [[ $? -ne 0 ]]
            then
            ecco 2
            echo 'Cant install packages (ABORT)'
            exit
         fi
         
         apt install -y add-apt-repository && ecco 2
      
      fi

      apt update -y
      add-apt-repository -y ppa:kelleyk/curl
    
    fi

    if [[ "$1" == "apache2" ]]
      then
      add-apt-repository -y ppa:andykimpe/apache2
    fi

    if [[ "$1" == "php" ]]
      then
      add-apt-repository -y ppa:sergey-dryabzhinsky/php80
    fi


    if [[ "$1" == "python3" ]]
      then
      add-apt-repository -y ppa:deadsnakes/ppa  
    fi
    
    apt update -y
    apt install $1 -y 
 
  fi

}

apt update
apt install -y curl && check_pack "curl"
apt install -y wget apache2 && check_pack "apache2" 
apt install -y php && check_pack "php" 
apt install -y python3 && check_pack "python3"
apt install -y libapache2-mod-php gcc

ecco 3 && echo $(ufw app list) && ecco 3

read -p "Enable APACHE SERVER on UFW? [Y][n] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
  ufw allow "Apache Full"
  ecco 2
  echo -n "UFW FIREWALL" $(ufw status)

else
  ecco 2
  echo "Skipping FIREWALL settings..."
fi

ecco 2
echo 'ServerName 127.0.0.1' >> /etc/apache2/apache2.conf

#basic
systemctl stop apache2
systemctl start apache2
systemctl restart apache2
systemctl reload apache2
systemctl status apache2 -l --no-pager 
systemctl enable apache2

ecco 3
read -p "Save HOST NETWORK Information? [Y]/[n] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
  ecco 2
  touch host.list
  echo $(hostname -I) >> host.list
  echo 'Saved...'

else
  
  ecco 2
  echo "Skipping enlisting..."

fi

ecco 2
read -p "Config Certbot? [y][N] " -n 1 -r
ecco 1

if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
  
  apt install -y certbot && check_pack "certbot" 
  apt install -y python3-certbot-apache && check_pack "python3-certbot-apache"
  
  if [[ $? -ne 0 ]]
    then
    ecco 2
    echo "Can't install certbot... (Configure PPA manually)"
  
  else
  
    ecco 2
    echo 'For SSL CERT:'
    ecco 2
    echo 'Config at: /etc/apache2/sites-available/*file*'
    echo '&&'
    echo 'Create symlink to /etc/apache2/sites-enabled/*'
    ecco 2
    echo 'Dont forget to add CNAME records!'
    read -p "Add auto for port: 80? [y][N] " -n 1 -r
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]
      then
    
      ecco 2
      echo -n 'Domain (format: example.com): '
      read domain
      ecco 1
      echo -n 'Subdomain (format: examplename || blank): '
      read subtmp
      ecco 1
      echo -n 'File name (not path): '
      read file
      if [[ "$subtmp" = "" ]]
        then
    
        sub=""
    
      else
    
        sub=$(echo -n $subtmp'.')
    
      fi
    
    
    mkdir /var/www/$file
    touch /var/www/error_$file.log
    touch /var/www/custom_$file.log
    echo """
Listen 80
<VirtualHost *:80>
ServerName $domain
ServerAlias www.$domain
ServerAlias $sub$domain
ServerAlias www.$sub$domain
DocumentRoot /var/www/$file
ErrorLog /var/www/error_$file.log
CustomLog /var/www/custom_$file.log combined
</VirtualHost>
    """ >> /etc/apache2/sites-available/$file
    # creating symlink
    ln -s /etc/apache2/sites-available/$file /etc/apache2/sites-enabled/
    
    ecco 2
    systemctl reload apache2
    echo -n 'Apache Config Test... '
    apache2ctl configtest
    
    fi
    ecco 3
    read -p "Run Certbot? [y][N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]
      then
      ecco 2
      read -p "Use email to get notifications? [y][N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Nn]$ ]]
        then
        certbot --apache
      else
        certbot --apache --register-unsafely-without-email
      fi
    fi    
  fi
  
echo
    
else
    ecco 2
    echo "Skipping certbot..."
fi


ecco 4
echo 'Finished!'
exit
