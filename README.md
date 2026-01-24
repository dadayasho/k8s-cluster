# K8s cluster on YC

Данный репозиторий содержит в себе руководство по поднятию self-managed K8s кластера на ресурсах Yandex Cloud.
---

# Бакет для state-file

Для реализации автоматизированного хранения `state-файла` компонентов кластера следует создать `bucket`.

В директории `bucket` находим файл `var.tfvars` и вписываем данные от `YC`.  

Далее иницилизируем `terraform`.
```yaml
terraform init
```
После инициализации `terraform` следует выполнить:
```yaml
terraform apply -auto-approve -var-file=var.tfvars
```
> [!IMPORTANT]  
> Тем самым на вашем облаке создаются ресурсы `bucket` и `setvice account`, которые понадобятся для
храниения `state-file` "кластера" удаленно в облаке.

# Создание виртуальных машин в YC

Кластер (в зависимости от типа) будет хоститься на виртуальных машинах. Для автоматизации подъема виртуальных машин так же используется `terraform`.  

Заходим в `/cluster`

> [!IMPORTANT]
> Так как `state-файл` хранится в облаке, следует экспортировать переменные окружения:
> AWS_ACCESS_KEY_ID - публичный ключ от сервисного аккаунта
> AWS_SECRET_ACCESS_KEY - закрытый ключ
> AWS_DEFAULT_REGION - регион
```yaml
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=" "
export AWS_DEFAULT_REGION="ru-central1"
```
Это нужно для того, чтобы стейт записывался через сервисный аккаунт у бакет.  
Далее выполняем комманды по инициализации и создаю ресурсов.

```yaml
terraform init
terraform apply -auto-approve -var-file=var.tfvars
```

> [!TIP]
> При условии, если кластер невысокодоступный (одна мастер нода), то следует поменять в