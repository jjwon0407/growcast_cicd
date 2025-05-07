#빌드 시 OpenJDK 17 기반 이미지 사용
FROM openjdk:17

COPY build/libs/growcast-0.0.1-SNAPSHOT.jar growcast.jar

EXPOSE 3030

#실행 명령
ENTRYPOINT ["java", "-jar", "/growcast.jar"]