#!/bin/bash   
#title          :zabbix-agent-install-rhel-ol.sh
#description    :Instalação do Zabbix Agent Versão 6 via Pacotes e Repositorio Oficial da Zabbix
#author         :Franco Tadeu Ferraciolli | https://github.com/FrancoTadeu
#date           :20240806
#version        :4.0.2  
#usage          :./zabbix-agent-install-rhel-ol.sh <Zbx-Server-Address>
#notes          : Informar o endereco do Zabbix-Server ou Zabbix-Proxy como unico argumento de execucao   
#bash_version   :5.1.16(1)-release
#============================================================================

# Variavel data atual para usar no Script
date=$(date +%Y-%m-%d)
# ANSI color codes
RED='\033[0;31m'
NC='\033[0m' # No Color

# Valida se o script esta sendo executado com parametro (argumento) necessario
if [ ! "$1" ]
then
   echo " *** Por favor informe o endereco IP e/ou DNS do Zabbix Server/Proxy como argumento de execucao ***"
   exit
else
   ZbxServer="$1"
fi

# Valida se o usuario em execucao e o root
if [ "$UID" -ne 0 ]; then
  echo "${RED} Permissao Negada. Por favor execute como root... \n ${NC}"
  exit
fi
# Valida se o sistema operacional e RHEL Like
if grep -qEi 'rhel|centos|oracle' /etc/os-release; then
  echo "Sistema operacional suportado detectado"
  echo "Iniciando instalacao do Zabbix Agent..."
else
  echo -e "${RED} Erro! \n Sistema operacional nao suportado. Este script e compativel apenas com RHEL, CentOS e Oracle Linux. ${NC}"
  exit
fi

sel_status=$(sestatus | head -n1 | awk -F ' ' '{print $3}')
if [ "$sel" -eq "enabled"]; then
    echo -e "${RED} SELINUX ATIVADO | PODE ACARRETAR PROBLEMAS PARA INICIAR O SERVICO \n DO ZABBIX AGENT \n ${NC}"
else
    echo -e "\n SELINUX Desativado: Status atual $sel_status \n"
fi


os_version=$(hostnamectl | grep "Operating System:" | awk -F '[()]' '{print $2}')

if [ "$os_version" == "Plow" ]; then
    version_number=9
    echo "excludepkgs=zabbix*" >> /etc/yum.repos.d/epel.repo
elif [ "$os_version" == "Ootpa" ]; then
    version_number=8
elif [ "$os_version" == "Maipo" ]; then
    version_number=7
elif [ "$os_version" == "Santiago" ]; then
    version_number=6
else
    echo -e "${RED} Erro! \n Versao do Sistema operacional RHEL $os_version nao compativel com o Zabbix Agent \n Finalizando execucao...${NC}"
    exit
fi
echo -e "INFO SO Version \n RHEL version number: $version_number\n"

# Download dos repositorios do zabbix
echo -e "Iniciando download do Zabbix Agent \n"
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/${version_number}/x86_64/zabbix-release-6.0-4.el${version_number}.noarch.rpm
dnf clean all

# Instala o Zabbix Agent e dependencias
echo -e "INICIANDO INSTALACAO DO AGENT - Output foi silenciado \n"
dnf install zabbix-agent lsof -y > /dev/null

# Modificar o arquivo de configuracao do Zabbix-Agent | Padrao checagem ativa - Necessario especificar o PID
cat <<EOF > /etc/zabbix/zabbix_agentd.conf
# Instalado via Shell Script em $date
# Script Criado por Dennis Silva e Franco Ferraciolli em 06/08/2024
PidFile=/run/zabbix/zabbix_agentd.pid
EnableRemoteCommands=1
#AllowKey=system.run[*]
BufferSend=12
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=20
Server=$ZbxServer
ServerActive=$ZbxServer
HostnameItem=system.hostname
HostMetadataItem=system.uname
Timeout=30
Include=/etc/zabbix/zabbix_agentd.d
EOF

echo -e "Habilitando servico do agent para iniciar no boot... \n"
systemctl restart zabbix-agent
systemctl enable --now zabbix-agent &> /dev/null

#Liberacao das portas do firewall
if systemctl status firewalld &> /dev/null
then
    echo -e " \n Firewalld instalado detectado. Criando regras de firewall para o Zabbix Agent"
    firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
    firewall-cmd --reload
else
    echo "Firewalld nao encontrado. Pulando etapa..."
fi

#Validacao da instalacao
echo -e '\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
echo '%%%%%%%%%%%%%%%% VALIDACAO DA INSTALACAO %%%%%%%%%%%%%%%%%%%%%%%%%%%'
echo -e '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n'

if lsof -i4TCP:10050 &> /dev/null
then
    echo -e "\n Porta do Zabbix Agent esta LISTENING \n"
else
    echo -e " \n ${RED} Porta do Agent nao esta em LISTENING ${NC} \n"
fi

systemctl status zabbix-agent | head -n5 | grep running
echo '###################################################################'
echo '#################  Zabbix Agent V6.0 instalado!  ##################'
echo '# O arquivo /etc/zabbix/zabbix_agentd.conf foi criado.            #'
echo '# O Estado running deve ser mostrado no comando acima             #'
echo '# Durante a execucao do script foram liberadas as porta 10050 e   #'
echo '# 10051 no firewalld.                                             #'
echo '# Caso o servico nao suba, considerar a destivacao do SELINUX     #'
echo '#                                                                 #'
echo '###################################################################'

