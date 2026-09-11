# Проверка пакетов на Zabbix agent

Скрипт agent_pkg.sh сравнивает текущий список установленных пакетов с сохранённым снимком и возвращает только изменения

Схема работы:

- считывает список пакетов из `/var/lib/dpkg/status`
- сохраняет текущий снимок в `/var/lib/zabbix/pkg_cache.txt`
- при следующем запуске сравнивает новый список со старым
- возвращает только изменения в виде текста
- если изменений нет — возвращает `OK: no package changes`

## Что возвращает скрипт

Теперь скрипт возвращает статусы:

- `INSTALLED pkg version` — пакет установлен
- `REMOVED pkg version` — пакет удалён
- `UPGRADED pkg old -> new` — пакет обновлён
- `OK: no package changes` — ничего не изменилось

---

# Как разворачивать на хостах

Плейбук zabbix_packages.yml должен использоваться на уже настроенных Zabbix agent

Он делает следующее:

- проверяет наличие `zabbix-agent`
- создаёт директорию `/etc/zabbix/zabbix_agentd.d`
- создаёт `/var/lib/zabbix` и назначает владельца `zabbix`
- добавляет `Include=/etc/zabbix/zabbix_agentd.d/*.conf`
- копирует agent_pkg.sh в `/usr/local/bin/agent_pkg.sh`
- копирует UserParameter из zabbix_agent_conf/pkg.conf
- валидирует конфиг и перезапускает агент

---

# Как настроить в Zabbix

## 1. Создать template

В веб-интерфейсе Zabbix:

- Configuration → Templates → Create template

Нужно обязательно заполнить:

- Template name: `Linux Package Changes`
- Template groups: выбрать или создать группу, например `Linux`

---

## 2. Создать item внутри template

Открыть шаблон `Linux Package Changes` → Items → Create item

Заполнить:

- Name: `Package updates check`
- Type: `Zabbix agent`
- Key: `custom.packages.check`
- Type of information: `Text`
- Update interval: `10s`
- History: `Store up to 31d`

---

## 3. Создать trigger внутри template

Открыть шаблон → Triggers → Create trigger

1. Trigger `Package installed on {HOST.NAME}`

```text
find(/Linux Package Changes/custom.packages.check,"INSTALLED")=1
```

2. Trigger `Package removed on {HOST.NAME}`

```text
find(/Linux Package Changes/custom.packages.check,"REMOVED")=1
```

3. Trigger `Package upgraded on {HOST.NAME}`

```text
find(/Linux Package Changes/custom.packages.check,"UPGRADED")=1
```

## 4. Привязать шаблон к существующим хостам

Для каждого хоста, который должен мониторить пакеты:

- Configuration → Hosts
- выбрать нужный host
- открыть его
- в разделе Templates нажать Add
- выбрать шаблон `Linux Package Changes`

---

## 5. Media type и уведомления в Discord

### Создать Media type

- Alerts → Media types → Create media type

Тип: Webhook

Параметры можно настроить под ваш Discord webhook. Обычно используется JSON с параметрами:

Пример JS-кода для webhook:

```javascript
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
```

Поставить галочку Enable

### Настроить пользователя

- Users → Users → выбрать пользователя
- Media → добавить Discord webhook
- Severity: Warning, Average, High, Disaster

---

## 6. Action

- Configuration → Actions
- Create action
- условия: Trigger value = PROBLEM
- операции: Send message
- Media type: Discord
