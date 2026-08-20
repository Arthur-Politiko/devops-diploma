# DevOps Diploma — Roadmap

## 0. Архитектура и подготовка
- [ ] Определить структуру репозиториев
- [ ] Определить CIDR
- [ ] Определить зоны доступности
- [ ] Определить security groups
- [ ] Определить IAM/service accounts
- [ ] Продумать стоимость ресурсов

## 1. Terraform / Cloud Infrastructure
- [ ] Service Account для Terraform
- [ ] Object Storage bucket
- [ ] Remote State
- [ ] VPC
- [ ] Subnets × 3 AZ
- [ ] NAT
- [ ] Route tables
- [ ] Security Groups
- [ ] Container Registry
- [ ] Проверить terraform apply
- [ ] Проверить terraform destroy
- [ ] Проверить повторный apply

## 2. Managed Kubernetes
- [ ] Regional Kubernetes Master
- [ ] 3 subnet'а
- [ ] Node Group
- [ ] Worker nodes
- [ ] Autoscaling
- [ ] Проверить доступ kubectl
- [ ] Настроить kubeconfig
- [ ] Проверить kubectl get pods -A
- [ ] Проверить сетевой доступ

## 3. Test Application
- [ ] Создать Git repository
- [ ] nginx/static application
- [ ] Dockerfile
- [ ] Собрать image
- [ ] Проверить image локально
- [ ] Push в Container Registry

## 4. Kubernetes Application Deployment
- [ ] Namespace
- [ ] Deployment
- [ ] Service
- [ ] ConfigMap (если нужен)
- [ ] Secret (если нужен)
- [ ] Проверить rollout
- [ ] Организовать HTTP-доступ
- [ ] Проверить приложение извне

## 5. Monitoring
- [ ] Helm
- [ ] kube-prometheus-stack
- [ ] Prometheus
- [ ] Grafana
- [ ] Alertmanager
- [ ] Node Exporter
- [ ] Проверить targets
- [ ] Проверить Kubernetes dashboards
- [ ] Организовать HTTP-доступ к Grafana

## 6. Terraform CI/CD
- [ ] Выбрать Terraform Cloud / Atlantis / CI
- [ ] Подключить Git repository
- [ ] terraform fmt
- [ ] terraform validate
- [ ] terraform plan
- [ ] terraform apply
- [ ] Сделать PR
- [ ] Получить plan
- [ ] Продемонстрировать pipeline

## 7. Application CI/CD
- [ ] Выбрать GitLab CI / Jenkins / TeamCity / GitHub Actions
- [ ] Pipeline
- [ ] Build Docker image
- [ ] Push image
- [ ] Tag image
- [ ] Deploy в Kubernetes
- [ ] Проверить автоматический deploy
- [ ] Проверить deploy по git tag

## 8. Финальная проверка
- [ ] Terraform repository
- [ ] Application repository
- [ ] Kubernetes manifests
- [ ] Docker image
- [ ] Grafana
- [ ] Test application
- [ ] CI/CD
- [ ] Screenshots
- [ ] PR / Terraform pipeline
- [ ] README
- [ ] Возможность показать всё с нуля