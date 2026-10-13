FROM wso2/wso2mi:4.3.0

USER root

RUN apt-get update && apt-get install -y curl && \
    curl -L -o /home/wso2carbon/wso2mi-4.3.0/lib/mysql-connector-j-8.0.33.jar \
    https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar && \
    chown wso2carbon:wso2 /home/wso2carbon/wso2mi-4.3.0/lib/mysql-connector-j-8.0.33.jar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER wso2carbon

ENV DB_HOST=localhost
ENV DB_PORT=3306
