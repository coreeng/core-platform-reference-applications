FROM gradle:8.6.0-jdk21
ADD . /opt/app
WORKDIR /opt/app

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "functional:clean", "functional:test"]
