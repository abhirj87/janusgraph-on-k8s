FROM openjdk:8-jre-slim-buster as cert_builder
RUN apt-get update; apt-get -y install curl && \
curl https://certs.secureserver.net/repository/sf-class2-root.crt -O && \
mkdir certificates && \
mv sf-class2-root.crt certificates/  && \
password=$(date +%s | md5sum | base64 | head -c 32; echo); echo $password > certificates/.storepass  && \
openssl x509 -outform der -in certificates/sf-class2-root.crt -out certificates/temp_file.der


FROM janusgraph/janusgraph:0.6.2
RUN mkdir truststore
#copy certificates
COPY --from=cert_builder /certificates /opt/janusgraph/certificates
COPY conf/janusgraph-server.yaml /opt/janusgraph/conf/janusgraph-server.yaml
#copy cql.conf
ADD conf /opt/janusgraph/conf
COPY conf/schema-script.groovy /opt/janusgraph/scripts/schema-script.groovy
COPY --chown=janusgraph:janusgraph bin/entrypoint.sh /opt/janusgraph/entrypoint.sh
RUN chmod 755 /opt/janusgraph/entrypoint.sh
#copy iam role based authenticator lib
COPY --chown=janusgraph:janusgraph target/es-aws-authenticator-0.6.2.jar /opt/janusgraph/lib/
#copy deps
ARG AWS_SDK_VER="2.17.270"
COPY --chown=janusgraph:janusgraph target/dependency/*${AWS_SDK_VER}.jar /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/esri* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/aws* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/amqp* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/checker* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/error* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/ion* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/j2objc* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/listenable* /opt/janusgraph/lib/
COPY --chown=janusgraph:janusgraph target/dependency/exp4j* /opt/janusgraph/lib/
# entrypoint
ENTRYPOINT [ "/opt/janusgraph/entrypoint.sh" ]