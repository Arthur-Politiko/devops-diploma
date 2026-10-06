# Образ Jenkins для стенда диплома.
#
# Список плагинов нельзя описать через JCasC — плагины должны стоять до старта,
# поэтому он прибит здесь и накатывается на этапе сборки образа. Это
# единственная часть конфигурации Jenkins, которая живёт не в JCasC.
#
# Docker CLI и buildx в образ не кладём: они монтируются с admin-ноды так же,
# как kubectl и terraform, — версии на хосте и в контейнере не разъезжаются.
FROM jenkins/jenkins:lts-jdk21

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
