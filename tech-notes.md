




## Init Process

* #### `0 wrapper.sh`
* * ####  `/discover-process.sh &`
* * * #### `/wait-for-host.sh ${SERVICE_NAME}${TASK_SLOT}`
* * ####  `/couchdb-process.sh &`
* * * #### `/home/couchdb/couchdb/bin/couchdb`
* * #### `/set-up-process.sh`
