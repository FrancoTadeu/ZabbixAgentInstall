#!/bin/bash -e
IPSERVER=$1
HOSTNAME=$2

# O script deve ser chamado usando os parametros, exemplo ./script.sh $1 $2 > ./script.sh 192.168.1.10 hostname
# Autor Franco Ferraciolli
# Todos os direitos reservados @Telic Technologies

if [ "$UID" -ne 0 ]; then
  echo "Por favor execute como root"
  exit 1
fi

# Download dos repositorios do zabbix

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf update -y

# Instala o Zabbix Agent e dependencias

dnf install zabbix-agent lsof -y

# Modificar o arquivo de configuracao do Zabbix-Agent

sed -i 's/Server=127.0.0.1/Server='$IPSERVER'/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive='$IPSERVER'/' /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf

systemctl restart zabbix-agent
systemctl enable --now zabbix-agent

#Liberacao das portas do firewall
firewall-cmd --add-service={http,https} --permanent
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --reload

#Validacao da instalacao
echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
echo %%%%%%%%%%%%%%%% VALIDACAO DA INSTALACAO %%%%%%%%%%%%%%%%%%%%%%%%%%%
echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lsof -i4TCP:10050
lsof -i6TCP:10050
lsof -i4TCP:10051 | head -n6
lsof -i6TCP:10051 | head -n6
systemctl status zabbix-agent | head -n5 | grep running

echo '###################################################################'
echo '##################  Zabbix Agent instalado!  ######################'
echo '# O arquivo /etc/zabbix/zabbix_agent.conf foi criado.             #'
echo '# O Estado running deve ser mostrado no comando acima  		        #'
echo '# Durante a execução do script foram liberadas as porta 10050 e	  #'
echo '# 10051 no firewalld.					                                   	#'
echo '# Caso o serviço não suba, considerar a destivação do SELINUX     #'
echo '# 								                                                #'
echo '###################################################################'
