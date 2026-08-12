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


