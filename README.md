1. Подготовка секретов  
Создайте директорию для секретов и сгенерируйте пароли  

mkdir -p secrets  
echo "slozhiy parol123" > secrets/MYSQL_ROOT_PASSWORD.txt  
echo "slozhiy parol123" > secrets/MYSQL_PASSWORD.txt    

2. Запустите контейнеры в фоновом режиме:

docker compose up -d

3. Monitoring → Hosts
В настройках хоста Zabbix server в настройках Host прописать DNS name "zabbix-agent" connect to "DNS"

4. Первоначальная настройка Zabbix
Откройте веб-интерфейс: http://IP:8080/  
Перейдите в Administration → General → Macros и установите макрос:  
{$ZABBIX.URL} = http://IP:8080/

5. Создание типа медиа (Media Type)  
Перейдите в Administration → Media types → Create media type:  
Name: Discord  
Type: Webhook  
Parameters:  
     Name                     Value  
alert.message             {ALERT.MESSAGE}  
alert.subject             {ALERT.SUBJECT}  
discord.endpoint https://discord.com/api/webhooks/ВАШ_ТОКЕН  
event.id                   {EVENT.ID}  
event.nseverity          {EVENT.NSEVERITY}  
trigger.id                  {TRIGGER.ID}  
user_agent          ZabbixServer (zabbix.com, 7.0)  
zabbix.url                  http://IP:8080/  

Поставить галочку возле Enable

7. Настройка пользователя
Перейдите в Users → Users → Admin → Media:
Type: Discord
Send to: URL вашего Discord Webhook
When active: 1-7,00:00-24:00
Use if severity: Отметьте Warning, Average, High, Disaster.

8. Создание Item
Перейдите Monitoring → Hosts → Zabbix server → Items
Create item
Name: Package updates check
Type: Zabbix agent
Key: custom.packages.check
Type: Text

9. Создание триггера
Перейдите Monitoring → Hosts → Zabbix server → Triggers
Name: Packages updates detected on {HOST.NAME}
Expressions → Add
Item → Select → Package updates check
Function: find()
O: like
V: UPDATED:
Result = 1

8. Настройка триггера
Перейдите в Alert → Actions → Trigges Actions
Перейдите во вкладку Report problems to Zabbix administrators и поставьте галочку возле Enabled
