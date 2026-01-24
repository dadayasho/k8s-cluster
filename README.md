# K8s cluster on YC

Данный репозиторий содержит в себе руководство по поднятию self-managed K8s кластера на ресурсах Yandex Cloud.
---

# Бакет для state-file

Для реализации автоматизированного хранения `state-файла` компонентов кластера следует создать `bucket`.

В директории `bucket` находим файл `var.tfvars` и вписываем данные от `YC`.  

Далее иницилизируем `terraform`.
```bash
terraform init
```
После инициализации `terraform` следует выполнить:
```bash
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
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=" "
export AWS_DEFAULT_REGION="ru-central1"
```
Это нужно для того, чтобы стейт записывался через сервисный аккаунт в бакет.  
Далее выполняем команды по инициализации и созданию ресурсов.

```bash
terraform init
terraform apply -auto-approve -var-file=var.tfvars
```

> [!TIP]
> При условии, если кластер невысокодоступный (одна мастер нода), то следует поменять в `cluster.tf` настройки, связанные с количеством инстансом ВМ в группе "master-plane"

# Настройка jump-on хоста

С этого хоста будет проводится настройка и управление виртуальными машинами, которые будут выполнять роль нод в кластере.

1) Добавляем IP-адресс виртуальной машины в `inventory-файл` для ansible по пути `/etc/ansible/hosts`
2) Выполняем плейбук `/ansible/ansible-playbook.yaml`
```bash
ansible-playbook ansible-playbook.yaml
```
Данный плейбук скопирует на ВМ плейбук для настройки нод, а именно `kubeadm-playbook.yaml` в рамках которого происходит подготовка ВМ к хосту кластера.

# Настройка кластера

Следует выполнить добавление IP-адрессов виртульных машин в `inventory-файл` в `/ansible-k8s/hosts` на `jump-on` машине.  
Далее следует выполнить плейбук `/ansible/kubeadm-playbook.yaml`

## Невысокодоступный кластер

Так как кластер невысокодоступный, то следует в группе `control-plane` иметь одну ВМ.  
1. Выполнить инициализацию кластера на `master ноде`.
```bash
sudo kubeadm init \
  --cri-socket=unix:///var/run/containerd/containerd.sock \
  --pod-network-cidr=192.168.0.0/16
```
Инициализируем кластер, в качестве рантайма используем `containerd`.

2. Настройка `kubectl`
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

3. Устанавливаем сетевой плагин `Flannel`
```bash
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sed -i 's/10.244.0.0\/16/192.168.0.0\/16/g' kube-flannel.yml
kubectl apply -f kube-flannel.yml
```
4. Присоединям `worker ноды` к кластеру через kubeadm join.

## Высокодоступный кластер
TBC...