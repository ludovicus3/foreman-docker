FROM registry.access.redhat.com/ubi9-minimal:latest AS builder

ARG JAVA_VERSION=17

RUN \
  microdnf update -y && \
  microdnf install -y git java-${JAVA_VERSION}-openjdk-devel jss gettext openssl wget tar && \
  microdnf clean all

# Prepare Tomcat
ARG TOMCAT_VERSION=9.0.76
RUN \
  wget https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz; \
  tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz; \
  mkdir /opt/tomcat; \
  mv apache-tomcat-${TOMCAT_VERSION}/* /opt/tomcat/

# Prepare Candlepin
ARG CANDLEPIN_VERSION=4.1.23-1
ARG BUILD_DIR=/candlepin
RUN mkdir -p ${BUILD_DIR}
WORKDIR ${BUILD_DIR}
RUN git clone --branch candlepin-${CANDLEPIN_VERSION} https://github.com/candlepin/candlepin.git ${BUILD_DIR}

ENV JAVA_HOME=/usr/lib/jvm/java

RUN ./gradlew --no-daemon war

RUN mv ${BUILD_DIR}/build/libs/candlepin-*.war /opt/tomcat/webapps/candlepin.war

FROM registry.access.redhat.com/ubi9-minimal:latest

ARG JAVA_VERSION=17
ENV JAVA_HOME=/usr/lib/jvm/jre-${JAVA_VERSION}-openjdk
ENV JRE_HOME=/usr/lib/jvm/jre-${JAVA_VERSION}-openjdk

RUN \
  microdnf update -y && \
  microdnf install -y java-${JAVA_VERSION}-openjdk-headless jss openssl && \
  microdnf clean all

COPY --from=builder /opt/tomcat /opt/tomcat
COPY server.xml /opt/tomcat/conf/server.xml
RUN \
  mkdir -p /etc/candlepin/certs; \
  ln -s /etc/candlepin/certs/* /etc/pki/ca-trust/source/anchors; \
  mkdir -p /var/cache/candlepin/sync; \
  groupadd -g 10000 tomcat; \
  useradd -g tomcat -u 10001 tomcat; \
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

EXPOSE 8080 8443

CMD ["/opt/tomcat/bin/catalina.sh", "run"]

