
# 1. Первоначальная настройка Zabbix
Откройте веб-интерфейс: http://IP:8080/  

Перейдите в Administration → General → Macros и установите макрос:  

{$ZABBIX.URL} = http://IP:8080/

# 2. Создание типа медиа (Media Type)  
Перейдите в Alerts → Media types → Create media type:  

Name: Discord  

Type: Webhook  

Parameters:  
alert.message → {ALERT.MESSAGE}  
alert.subject → {ALERT.SUBJECT}  
discord.endpoint → https://discord.com/api/webhooks/TOKEN  
event.id → {EVENT.ID}  
event.nseverity → {EVENT.NSEVERITY}  
trigger.id → {TRIGGER.ID}  
user_agent → ZabbixServer (zabbix.com, 7.0)  
zabbix.url → http://IP:8080/  

Если тест Discordа будет ругаться, то скрипт который вставляется ниже:

    try {
        var params = JSON.parse(value);

        var req = new HttpRequest();
        req.addHeader('Content-Type: application/json');

        var resp = req.post(params.discord_endpoint, JSON.stringify({
            username: 'Zabbix',
            content: params.alert_subject + '\n' + params.alert_message
        }));

        var code = req.getStatus();
        if (code != 200 && code != 204) {
            throw 'Discord HTTP Error: ' + code + ' ' + resp;
        }
        return 'OK';
    }
    catch (e) {
        throw e;
    }

Поставить галочку возле Enable

# 3. Настройка пользователя
Перейдите в Users → Users → Admin → Media:

Type: Discord

Send to: URL вашего Discord Webhook

When active: 1-7,00:00-24:00

Use if severity: Отметьте Warning, Average, High, Disaster.

# 4. Создание Item
Перейдите Monitoring → Hosts → Zabbix server → Items

Create item

Name: Package updates check

Type: Zabbix agent

Key: custom.packages.check

Type: Text

# 5. Создание триггера
Перейдите Monitoring → Hosts → Zabbix server → Triggers

Name: Packages updates detected on {HOST.NAME}

Expressions → Add

Item → Select → Package updates check
Function: find()
O: like
V: UPDATED:
Result = 1

# 6. Настройка триггера
Перейдите в Alert → Actions → Trigges Actions

Перейдите во вкладку Report problems to Zabbix administrators и поставьте галочку возле Enabled
