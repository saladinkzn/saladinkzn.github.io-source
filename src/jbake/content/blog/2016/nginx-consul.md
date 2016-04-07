title=Docker+Consul+Nginx, используем Service Discovery для конфигурирования Reverse Proxy
date=2016-04-06
type=post
tags=blog
status=draft
~~~~~~

# Зачем это вообще нужно?

Изведав Service Discovery в действии на примере Solr Cloud, я возжелал использовать этот подход как можно шире.
Что может быть лучше, чем возможность просто добавить еще один сервер, а он уже сам заберёт настройки из хранилища,
узнает об остальных запущенных серверах и т.д.

Solr использует для Service Discovery Zookeeper, что и понятно: Zookeeper, как и Solr являются проектами инкубатора
Apache. Но, если уж начистоту, то Zookeeper достаточно сложное для использования хранилище: Service Discovery, например,
для него приходится реализовывать самостоятельно. Существует специальный проект Curator, который реализует основные
шаблоны работы с Zookeeper.

Поисследовав немного существующие проекты, я пришел к выводу что самым удачным для моих задач является [http://consul.io](Consul).
Наиболее интересным фишками Consul является:

 * Возможность запуска consul-агентов на каждой машине вашей инфраструктуры. Это позволяет вашим сервисам всегда обращаться
 к Consul по заранее известному адресу, соответственно, не нужно конфигурировать адрес Consul (в случае использования
 Zookeeper необходимо указывать все хосты, на которых расположен ваш Ensemble Zookeeper'а).
 * Consul позволяет легко регистрировать даже те сервисы, которые не умеют с ним интегрироваться. Для этого consul-agent
 может быть сконфигурирован соответствующим образом, что при старте он будет регистрировать заданные сервисы, а также HealthCheck для них. (С Zookeeper для этого придется использовать некое приложение, которое будет держать эфемерный
 узел в соответствующем узле дерева Zookeeper).
 * Consul позволяет использовать health сheck, при этом он может следить за нагрузкой на IO, объемом потребляемой памяти,
нагрузкой на центральный процессор, опрашивать определенный HTTP endpoint и многое другое.
 * Для работы с Consul используется человекочитаемое REST API.

# Как мы будем использовать Consul?

В данной статье мы будем использовать Consul для автоматической регистрации различных сервисов в реверс-прокси (Nginx). Nginx не поддерживает интеграцию с Consul из коробки, поэтому мы будем использовать подход с генерацией конфигурационного файла и вызова nginx reload.

Для того чтобы сгенерировать конфигурационный файл, нам нужен какой-нибудь инструмент, который бы смог получать нужные данные из консула. Вообще, так как нам доступен Rest API, мы бы могли грузить информацию о зарегистрированных сервисах с помощью простого python-скрипта. Но лучше не городить велосипеды, а воспользоваться решением от авторов Consul: consul-template.

**consul-template** - аналог confd, но нативно поддерживающий Service Discovery Consul. Позволяет как сгенерировать конфиграционный файл однажды, так и следить за изменениям в выбранном сервисе и автоматически перегенерировать файл в случае изменений.

# Поднимаем всё в Docker.

Строить инфраструктуру мы будем на основе Docker. Это позволит нам не возиться с установкой каждого сервиса в отдельности, получить готовое решение, которое можно будет легко развернуть как на одном, так и на нескольких серверах.

1. Consul
Для Consul мы будем использовать готовый образ: `gliderlabs/consul-server`.
Запустим его с помощью команды
```
docker -d -p 8500:8500 --net consul gliderlabs/consul-server --bootstrap
```

2. Зарегистрируем наш сервис с помощью REST API
```
curl -X PUT 'http://localhost:8500/v1/agent/service/register --data '{ "ID": "jenkins", "Name": "web", "Address": "jenkins", "Port": 8080
```

3. Создадим образ с использованием nginx и consul-template

    * Dockerfile:

        ```
        FROM debian:jessie
        MAINTAINER sala

        # Устанавливаем  nginx, curl и unzip
        RUN apt-get update && apt-get install curl unzip nginx -y
        # Скачиваем consul-template, распаковываем, готовим папку для шаблончиков
        RUN curl -L https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip -o consul-template.zip && \
         unzip consul-template.zip -d /usr/local/bin && \
         cd /usr/local/bin && \
         chmod +x consul-template && \
         mkdir -p /etc/consul-template/templates
        # Публикуем стандартные порты для http и https
        EXPOSE 80
        EXPOSE 443
        # Добавляем шаблон, конфигурационный файл nginx и скрипт запуска
        ADD templates/ /etc/consul-template/templates
        ADD nginx.conf /etc/nginx/nginx.conf
        ADD scripts/start.sh .
        CMD ./start.sh
        ```

    * templates/nginx.ctmpl

        ```
        {{range service "web"}}
        server {
            server_name {{.ID}}.shadam.ru;
            location / {
                proxy_pass http://{{.Address}}:{{.Port}};
                proxy_connect_timeout 90;
                proxy_send_timeout 90;
                proxy_read_timeout 90;

                proxy_buffers                   8 64k;
                proxy_buffer_size               64k;
                proxy_busy_buffers_size         64k;
                proxy_temp_file_write_size      10m;

                proxy_set_header        Host            $http_host;
                #proxy_set_header       Host            $host;
                proxy_set_header        Referer         $http_referer;
                proxy_set_header        User-Agent      $http_user_agent;proxy_redirect off;
                proxy_set_header        X-Real-IP       $remote_addr;
                proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header        X-Forwarded-Proto       $scheme;

                client_max_body_size    64m;
                client_body_buffer_size 1m;
            }
        }

        {{end}}
        ```

    * scripts/start.sh

        ```
        #!/bin/bash

        set -eo pipefail

        export CONSUL_PORT=${CONSUL_PORT:-8500}
        export HOST_IP=${HOST_IP:-consul}
        export CONSUL=$HOST_IP:$CONSUL_PORT

        echo "[nginx] booting container. CONSUL: $CONSUL."

        # Try to make initial configuration every 5 seconds until successful
        consul-template -once -retry 5s -consul $CONSUL -template "/etc/consul-template/templates/nginx.ctmpl:/etc/nginx/conf.d/consul-template.conf"

        # Put a continual polling `confd` process into the background to watch
        # for changes every 10 seconds
        consul-template  -consul $CONSUL -template "/etc/consul-template/templates/nginx.ctmpl:/etc/nginx/conf.d/consul-template.conf:service nginx reload" &
        echo "[nginx] consul-template is now monitoring consul for changes..."

        # Start the Nginx service using the generated config
        echo "[nginx] starting nginx ..."
        nginx
        ```

Теперь мы можем построить наш образ с помощью команды
```
    docker build -t saladinkzn/nginx-consul-template .
```

После того как мы построили образ, мы можем его запустить.
```
    docker run -d -p 80:80 --net consul saladinkzn/nginx-consul-template
```

Ура! Теперь у нас есть работающий Nginx, который автоматические создает дополнительные записи в своем конфиге для каждого добавленного сервиса.

Что нам это дает? Возможность 1 раз сконфигурировать данную подсистему и далее легко устанавливать дополнительные сервисы, автоматически получая сконфигурированный Nginx.