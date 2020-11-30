FROM openjdk:8 

RUN cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN echo "Asia/Seoul" > /etc/timezone
RUN mkdir -p /app/logs
ADD app-1.0.jar /app
EXPOSE 8080
WORKDIR /app
CMD ["java", "-jar", "app-1.0.jar"]