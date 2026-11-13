FROM --platform=$BUILDPLATFORM maven:3.9.9-eclipse-temurin-21-jammy AS BUILD

WORKDIR /app

COPY pom.xml .

COPY src ./src

RUN mvn dependency:go-offline

RUN mvn clean install -DskipTests

FROM tomcat:10-jdk21

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=BUILD target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD [ "catalina.sh", "run" ]