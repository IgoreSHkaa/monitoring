# Проверка пакетов на Zabbix agent

Скрипт agent_pkg.sh сравнивает текущий список установленных пакетов с сохранённым снимком и возвращает только изменения

Схема работы:

- считывает список пакетов из `/var/lib/dpkg/status`
- сохраняет текущий снимок в `/var/lib/zabbix/pkg_cache.txt`
- при следующем запуске сравнивает новый список со старым
- возвращает только изменения в виде текста
- если изменений нет — возвращает `OK: no package changes`

## Что возвращает скрипт

Теперь скрипт возвращает понятные статусы:

- `INSTALLED pkg version` — пакет установлен
- `REMOVED pkg version` — пакет удалён
- `UPGRADED pkg old -> new` — пакет обновлён
- `OK: no package changes` — ничего не изменилось

Примеры:

```text
INSTALLED tree 2.3.1-1
REMOVED curl 7.88.1-10ubuntu0.1
UPGRADED openssl 3.0.0 -> 3.0.2
OK: no package changes
```

Ключ Zabbix:

```text
custom.packages.check
```

Это значение отдаёт Zabbix agent через UserParameter

---

# Как разворачивать на хостах

Плейбук zabbix_packages.yml должен использоваться на уже настроенных Zabbix agent

Он делает следующее:

- проверяет наличие `zabbix-agent`
- создаёт директорию `/etc/zabbix/zabbix_agentd.d`
- создаёт `/var/lib/zabbix` и назначает владельца `zabbix`
- добавляет `Include=/etc/zabbix/zabbix_agentd.d/*.conf`
- копирует agent_pkg.sh] в `/usr/local/bin/agent_pkg.sh`
- копирует UserParameter из zabbix_agent_conf/pkg.conf
- валидирует конфиг и перезапускает агент

---

# Как настроить в Zabbix

## 1. Создать template

В веб-интерфейсе Zabbix:

- Configuration → Templates → Create template

Нужно обязательно заполнить:

- Template name: `Linux Package Changes`
- Visible name: `Linux Package Changes`
- Template groups: выбрать или создать группу, например `Linux`

После сохранения шаблон будет готов к привязке к хостам

---

## 2. Создать item внутри template

Открыть шаблон `Linux Package Changes` → Items → Create item

Заполнить:

- Name: `Package updates check`
- Type: `Zabbix agent`
- Key: `custom.packages.check`
- Type of information: `Text`
- Update interval: `30s` или `60s`
- History: `Do not store` или `Store up to 31d`

Важно: item должен быть `Text`, потому что значение возвращается строкой

---

## 3. Создать trigger внутри template

Открыть шаблон → Triggers → Create trigger

Основная идея: один trigger на один тип события или один trigger на любой тип изменения


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

После этого item и trigger из шаблона появятся у host.

Не нужно создавать отдельный trigger на каждом хосте вручную.

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

После этого Zabbix будет отправлять уведомления на Discord при фактическом появлении события.

---

## 7. Проверка

После деплоя и привязки шаблона к хосту:

- Agent должен возвращать `custom.packages.check`
- item должен хранить значения в Latest data
- trigger должен переходить в Problem при `INSTALLED`, `REMOVED` или `UPGRADED`
- Action должен отправлять уведомление в Discord

Если изменений нет — агент возвращает:

```text
OK: no package changes
```

И trigger не должен срабатывать

---

# Кратко: что надо сделать в Zabbix

1. создать template `Linux Package Changes`
2. создать item `custom.packages.check` типа `Text`
3. создать trigger/триггеры на `INSTALLED`, `REMOVED`, `UPGRADED`
4. привязать template к хостам
5. настроить Discord webhook как Media type
6. создать Action на PROBLEM

Так вы получаете один шаблон, который можно навесить на все нужные Linux-хосты без дублирования trigger на каждом хосте отдельно
