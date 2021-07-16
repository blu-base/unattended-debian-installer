myperms=$(shell id -u).$(shell id -g)

all: clean clean
	-docker stop image-builder
	-docker rm image-builder
	docker run -itd --name image-builder --mount type=bind,source=$(shell pwd),target=/work image-builder/debian-image
	docker exec -it image-builder make build

build:
	tar -pczf extras.tar.gz extras/
	build-simple-cdd --conf custom.conf --auto-profiles custom --locale en_US --keyboard us --force-root --force-preseed
	rm extras.tar.gz

build-unattended:
	[ ! "$(docker ps -a | grep image-builder)" ] || echo "The container image-builder is not running"
	docker exec -it image-builder bash buildFullyUnattended.sh

image:
	docker build -t image-builder/debian-image .
	touch $@


clean:
	sudo chown -R $(myperms) .
	rm -rf tmp images image extras.tar.gz md5sum.txt


