FROM debian:10
RUN apt update && apt install -y simple-cdd make tasksel

WORKDIR /work
