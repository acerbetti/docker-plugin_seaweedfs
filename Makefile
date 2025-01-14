PLUGIN_NAME = seaweedfs-volume-plugin
PLUGIN_TAG ?= amd64
PRIVATE_REGISTRY ?= registry.caplaz.com

all: clean rootfs create

clean:
	@echo "### rm ./plugin"
	@rm -rf ./plugin

config:
	@echo "### copy config.json to ./plugin/"
	@mkdir -p ./plugin
	@cp config.json ./plugin/

rootfs: config
	@echo "### docker build: rootfs image with"
	@docker build -t ${PLUGIN_NAME}:${PLUGIN_TAG} --build-arg http_proxy=${http_proxy} --build-arg https_proxy=${https_proxy} .
	@echo "### create rootfs directory in ./plugin/rootfs"
	@mkdir -p ./plugin/rootfs
	@docker create --name tmp ${PLUGIN_NAME}:${PLUGIN_TAG}
	@docker export tmp | tar -x -C ./plugin/rootfs
	@docker rm -vf tmp

create:
	@echo "### remove existing plugin ${PLUGIN_NAME}:${PLUGIN_TAG} if exists"
	@docker plugin rm -f ${PLUGIN_NAME}:${PLUGIN_TAG} || true
	@echo "### create new plugin ${PLUGIN_NAME}:${PLUGIN_TAG} from ./plugin"
	@docker plugin create ${PLUGIN_NAME}:${PLUGIN_TAG} ./plugin


create_private:
	@echo "### remove existing plugin (for private registry) ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG} if exists"
	@docker plugin rm -f ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG} || true
	@echo "### create new plugin (for private registry) ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG} from ./plugin"
	@docker plugin create ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG} ./plugin

enable:
	@echo "### enable plugin ${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin enable ${PLUGIN_NAME}:${PLUGIN_TAG}

disable:
	@echo "### disable plugin ${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin disable ${PLUGIN_NAME}:${PLUGIN_TAG}

push:  clean rootfs create enable
	@echo "### push plugin ${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin push ${PLUGIN_NAME}:${PLUGIN_TAG}

push_private: clean rootfs create_private
	@echo "### push plugin ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin push ${PRIVATE_REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG}
