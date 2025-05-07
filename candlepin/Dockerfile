FROM registry.access.redhat.com/ubi9-minimal:latest AS builder

ARG JAVA_VERSION=17

RUN \
  microdnf update -y && \
  microdnf install -y git java-${JAVA_VERSION}-openjdk-devel jss gettext openssl tar && \
  microdnf clean all

# Prepare Tomcat
ARG TOMCAT_VERSION=9.0.76
ADD https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz /
RUN \
  tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz; \
  mkdir /opt/tomcat; \
  mv apache-tomcat-${TOMCAT_VERSION}/* /opt/tomcat/; \
  rm -rf /opt/tomcat/webapps/docs /opt/tomcat/webapps/examples

RUN echo "org.apache.tomcat.util.digester.PROPERTY_SOURCE=org.apache.tomcat.util.digester.EnvironmentPropertySource" >> /opt/tomcat/conf/catalina.properties

# Prepare Candlepin
ARG CANDLEPIN_VERSION=4.2.17-1
ARG BUILD_DIR=/candlepin
RUN mkdir -p ${BUILD_DIR}
WORKDIR ${BUILD_DIR}
RUN git clone --branch candlepin-${CANDLEPIN_VERSION} --single-branch https://github.com/candlepin/candlepin.git ${BUILD_DIR}

ENV JAVA_HOME=/usr/lib/jvm/java

RUN ./gradlew --no-daemon war

RUN \
  set -eux; \
  mkdir /opt/tomcat/webapps/candlepin; \
  cd /opt/tomcat/webapps/candlepin; \
  jar xvf ${BUILD_DIR}/build/libs/candlepin-${CANDLEPIN_VERSION%%-*}.war

#RUN mv ${BUILD_DIR}/build/libs/candlepin-*.war /opt/tomcat/webapps/candlepin.war;

FROM registry.access.redhat.com/ubi9-minimal:latest

ARG JAVA_VERSION=17
ENV JAVA_HOME=/usr/lib/jvm/jre-${JAVA_VERSION}-openjdk
ENV JRE_HOME=/usr/lib/jvm/jre-${JAVA_VERSION}-openjdk

RUN \
  microdnf update -y && \
  microdnf install -y java-${JAVA_VERSION}-openjdk-headless jss openssl gettext && \
  microdnf clean all

COPY --from=builder /opt/tomcat /opt/tomcat
COPY server.xml /opt/tomcat/conf/server.xml
RUN \
  mkdir -p /etc/candlepin/certs; \
  mkdir -p /var/cache/candlepin/sync; \
  groupadd -g 10000 tomcat; \
  useradd -g tomcat -u 10001 tomcat;

COPY broker.xml /etc/candlepin/broker.xml
COPY candlepin.conf.template /etc/candlepin/candlepin.conf.template
COPY logback.xml /opt/tomcat/webapps/candlepin/WEB-INF/classes/logback.xml
COPY login.config cert-roles.properties /opt/tomcat/conf/
COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN \
  ln -s jss.jar /usr/lib/java/jss4.jar; \
  chmod +x /usr/bin/entrypoint.sh; \
  chown -R tomcat:tomcat /opt/tomcat; \
  chown -R tomcat:tomcat /var/log/; \
  chown -R tomcat:tomcat /var/lib/; \
  chown -R tomcat:tomcat /etc/candlepin/; \
  chown -R tomcat:tomcat /var/cache/; \
  chown -R tomcat:tomcat /etc/pki/; \
  chmod -R 775 /opt/tomcat/webapps; \
  chmod -R 775 /var/log/;

WORKDIR /opt/tomcat/bin

USER tomcat

ENV KEYSTORE=/etc/candlepin/certs/keystore
ENV TRUSTSTORE=/etc/candlepin/certs/truststore
ENV KEYSTORE_PASSWORD=""
ENV TRUSTSTORE_PASSWORD=""

EXPOSE 8443 61613

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/opt/tomcat/bin/catalina.sh", "run"]

