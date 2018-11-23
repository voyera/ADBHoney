FROM python:2.7.15-alpine3.8

RUN pip install hexdump
RUN mkdir -p /adb/data
COPY main.py /adb/main.py
COPY protocol.py /adb/protocol.py
EXPOSE 5555/tcp

ENTRYPOINT ["python", "/adb/main.py"]