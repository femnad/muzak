all: init

init:
	terraform init -backend-config=gcs-backend-config.secret

upgrade:
	terraform init -backend-config=gcs-backend-config.secret -upgrade
