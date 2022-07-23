#!/bin/bash -e
IPSERVER=$1
HOSTNAME=$2
# O script deve ser chamado usando os parametros, exemplo ./script.sh $1 $2 > ./script.sh 192.168.1.10 hostname
# Autores Franco Ferraciolli e Guilherme Festozo
# Todos os direitos reservado @Telic Technologies

if [ "$UID" -ne 0 ]; then
  echo "Por favor execute como root"
  exit 1
fi

#Baixa e instala os repositorios do zabbix
wget -S https://repo.zabbix.com/zabbix/5.0/debian/pool/main/z/zabbix-release/zabbix-release_5.0-2+debian11_all.deb
dpkg -i zabbix-release_5.0-2+debian11_all.deb

# Para Debian e Ubuntu
if [ -x /usr/bin/apt-get ]; then
  apt-get update
  apt-get -y install zabbix-agent sysv-rc-conf lsof
  sysv-rc-conf zabbix-agent lsof on
  sed -i 's/Server=127.0.0.1/Server='$IPSERVER'/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/ServerActive=127.0.0.1/ServerActive='$IPSERVER'/' /etc/zabbix/zabbix_agentd.conf
  sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  service zabbix-agent restart
  service zabbix-agent enable
  lsof -i4TCP:10050
  lsof -i6TCP:10050
  fi 
  
  
  