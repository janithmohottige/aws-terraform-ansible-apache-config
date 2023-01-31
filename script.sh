terraform apply --auto-approve

echo [webservers] >> hosts

while [ -z "$var1" ];
do
        terraform apply --auto-approve
        var1=$(terraform output dest-ip) ; var1="${var1%\"}" ; var1="${var1#\"}" ; echo $var1 >> hosts
done

while [ -z $var2 ];
do
        terraform apply --auto-approve
	var2=$(terraform output prod-ip) ; var2="${var2%\"}" ; var2="${var2#\"}" ; echo $var2 >> hosts
done

echo Production Server IP is $var1
echo Destination Server IP is $var2

a=1
while [ $a -eq 1 ];
do
        if ping -c 2 $var1>/dev/null
        then
                echo Ping Server 1 successfull
                a=2
        else
                echo failure
        fi
done

echo Server 1 Up and Running

b=1
while [ $b -eq 1 ];
do
        if ping -c 2 $var2>/dev/null
        then
               echo Ping Server 2 successfull
               b=2
        else
               echo Failure  
        fi
done

echo Server 2 Up and Running

echo Running Ansible Playbook

ansible-playbook ansible.yml -u ec2-user --private-key ~/yesh/access.pem
