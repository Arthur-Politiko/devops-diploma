1. Подрезать права у sa проекта облака


2. Подготовка БЭКЭНДА для tf
Читаем [тут](https://developer.hashicorp.com/terraform/language/backend), что 
```
Do not configure a backend when connecting your configuration to workspaces in HCP Terraform or Terraform Enterprise. These systems automatically manage state in the workspaces associated with your configuration. If your configuration includes a cloud block, it cannot include a backend block.
```
Значит, подготовка s3 и бэкэнда должна происходить или средствами отдельного tf файла-проекта или скриптом

Не забываем, что для работы с s3 для terraform нужны свои credentials, а именно access_key_id и secret_access_key статического ключа. Только access_key_id это на самом деле key_id из выхлопа примерно такой команды:
```bash
yc iam access-keys list --service-account-id="ajeci4s6cdan53143ob7"
```
Перенести создание sa в `./bootstrap/`
Перенести создание статического ключа в `00-bootstrap.sh`?
Перенести в код `./bootstrap/` инициализацию .env значениями из файла `./vault/s3_key`

Создаю ssh ключи в `00-bootstrap.sh`
Закидываю ключи в `yandex cloud`
Создаю OSLogin профиль в `yandex cloud` [смотри_тут](https://yandex.cloud/ru/docs/organization/operations/os-login-profile-create#cli_1)

Но на самом деле это всё лишнее. Вот рабочая рекомендация от самого провайдера:
```
Примечание

На создаваемой ВМ желательно создать локального пользователя и отдельно передать для него SSH-ключ: так вы сможете подключиться к ВМ по SSH даже в том случае, если отключите для нее доступ по OS Login. Создать локального пользователя ВМ и передать SSH-ключ для него можно с помощью метаданных.

Для пользователей, добавленных через метаданные:

после включения доступа к ВМ по OS Login из метаданных удаляются ключи, указанные в user-data и ssh-keys;
после отключения доступа к ВМ по OS Login удаленные ключи пересоздаются.

```
То есть, создаём сами локального пользователя и передаем SSH-ключ для него, а потом, если захочется, включаем `oslogin`.

Плюс ко всему, добавление ключа происходит только для новых машин. То есть имея свой готовый образ мы должны:
`Установите на виртуальную машину агент OS Login. Выполните команду в зависимости от операционной системы ВМ:` 
Ubuntu 24.04
```curl https://storage.yandexcloud.net/oslogin-configs/ubuntu-24.04/config_oslogin.sh | bash```


Проверить table route
Проверить security group на адекватность

3. Переходим в каталог `tf` и выполняем команду:
```bash
terraform init -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"
```

Заменить $ACCESS_KEY и $SECRET_KEY на команды чтения файла `./vault/s3_key`


4. Выполняем команду:
```bash
terraform apply
terraform destroy
```
Убедились что на текущем этапе всё корректно. 

Проверить как лучше загнать vm k8s в группу vm, для автоматического масштабирования


В качестве `control node` будет выступать наша текущая машина.
Прикинуть, можно ли для шаблона `ansible` использовать для каждой vm своего пользователя
5. Убрать константы при генерации конфигов `ansible`

Добавить все хосты в `inventory.ini`


6. Давай порассуждаем как происходит разворачивание `terraform` через `ansible`

Что нужно для работы:
- Развернутые хосты
- Nat хост
- Установленный на хостах python
- Credentials для доступа к хостам
- Доступ к хостам по ssh
- Доступ хостов к сети интернет

Запускаем на локальной машине (это вполне себе вопрос, откуда запускать разворачивание инфраструктуры, по хорошему необходимо иметь `admin` хост и делать все дела с него, но пока делаем это на нашей локальной машине) playbook

```bash
ansible-playbook 90-install-k8s.yaml
```

В `90-install-k8s.yaml` прописаны последовательно те `playbook` которые необходимо запустить для деплоя необходимой инфраструктуры для `k8s`

`01-bootstrap.yaml` 
Вообще очень простая вещь. Пытаемся привести узлы в чувство, устанавливаем python, затем пытаемся проверить как прошла процедура, собираем факты (требует python) ну и вызываем `ansible.builtin.apt`

`02-nat-gateway.yaml`
Стандартный путь настройки nat хоста, не используем python

`05-k8s-common.yaml`
В сети много примеров как настроить под k8s. Пример [вот](https://github.com/TokarenkoKonstantin/ansible-k8s)

На узлах `masters:workers` пытаемся:

Мне кажется очень простая, а значит красивая вещь
    05-1 Указываем на хостах ip адрес API-сервера (фактически на control-plane node, то есть на master-ноде где крутится процесс `kube-apiserver`). 

Обновляем перечень пакетов

Устанавливаем необходимые пакеты:
- apt-transport-https
- ca-certificates
- curl
- gnupg
- lsb-release
- unattended-upgrades
- software-properties-common

Отключаем `swap` и убираем его из `fstab`

Далее по рекомендации подключаем модули overlay и br_netfilter для `containerd` 
и настраиваем их, а именно: завоорачиваем трафик из мостов в iptables и раазрешаем проброс трафика между портами. Загружается это всё из `/etc/sysctl.d/k8s.conf` командой `sysctl --system`

* Create keyrings directory - создаём папку для ключей;
* Download Kubernetes GPG key / Download Docker GPG key - кладём ключи репозитория в папку;
* Add Kubernetes repository / Add Docker repository - подключаем APT-репозитории которые и будут проверяться этими ключами.

В `05-12 Refresh facts after repository setup` перечитываем факты. Прикольный костыль




```
- name: "01 Bootstrap Kubernetes nodes"
  import_playbook: 01-bootstrap.yaml

- name: "05 Prepare Kubernetes nodes"
  import_playbook: 05-k8s-common.yaml

- name: "10 Configure Kubernetes master nodes"
  import_playbook: 10-master.yaml

- name: "20 Initialize Kubernetes cluster"
  import_playbook: 20-kubeadm-init.yaml

- name: "21 Join worker nodes to cluster"
  import_playbook: 21-kubeadm-join.yaml

- name: "22 Join additional master nodes"
  import_playbook: 22-kubeadm-join-master.yaml

```




Создали каталог web-app в который поместили Dockerfile и файл конфигурации nginx а так же index.html. 
Запекаем образ следующей командой: 
```
docker build . -t cr.y
andex/crpm7r21f2egucb6leru/nginx:server
```
где `crpm7r21f2egucb6leru` это id из `yandex_container_registry->registry_id`

далее, для того чтобы его запушить в `registry` необходимо настроить доступ в этот `registry`. На текущий момент true путь это использование iam токенов и следующей команды:
```
echo <IAM-токен>|docker login \
  --username iam \
  --password-stdin \
  cr.yandex
```

Запросить токен можно вот такой командой:
```
yc iam create-token
```
или записать в переменную:
```
export IAM_TOKEN=`yc iam create-token`
```
загрузка image в registry осуществляется командой:
```
docker push cr.yandex/crpm7r21f2egucb6leru/nginx:server
```
Просмотреть список images можно вот такой командой:
bash```
yc container image list
```
Важно и необычно!
```
Когда ты делаешь docker push, registry загружает каждый слой отдельно и хранит их как независимые объекты. Поэтому в списке репозитория ты видишь не один образ, а столько записей, сколько слоёв у твоего образа.
```


---
### Теперь `observing`

