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

