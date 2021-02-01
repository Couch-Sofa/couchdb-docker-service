#!/bin/bash

# The primary node is couchdb1 and is the single node with which all secondary nodes register their
# membership. The primary node and secondary node designation only really matters during the setup
# process and is only used to implement a scalable service architecture.

# Wait until primary node is ready
/wait-for-host.sh couchdb1 && /wait-for-it.sh couchdb1:5984 -t 300  # && /wait-for-it.sh couchdb1:5986 -t 300

## CouchDB 3.0+ in clustered mode uses the port 5984, just as in a standalone configuration.
## !!! Port 5986, previously used in CouchDB 2.x, has been removed in CouchDB 3.0.
## All endpoints previously accessible at that port are now available under the /_node/{node-name}/... hierarchy via the primary 5984 port.





if [ $TASK_SLOT -eq 1 ]; then
  echo "Setting up primary node..."

  # Create system databases if they don't already exist
  missing=`curl -s -x GET http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb1:5984/_users | grep 'not_found'`

  if [ "$missing" ]; then
    # Sleep so that when we create the databases, they will be distributed over all our nodes
    sleep 60
    curl -s -x PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb1:5984/_users
    curl -s -x PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb1:5984/_replicator
    curl -s -x PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb1:5984/_global_changes
  fi
else
  echo "Setting up secondary node..."

  # Wait until secondary node is ready
  /wait-for-host.sh couchdb$TASK_SLOT && /wait-for-it.sh couchdb$TASK_SLOT:5984 -t 300 #&& /wait-for-it.sh couchdb$TASK_SLOT:5986 -t 300

  # Register membership. We need to register couchdb1 with this node (couchdb$TASK_SLOT) and not
  # vise-versa as this way, we can use `/wait-for-host.sh couchdb1` to guarantee that we have a
  # clear route to couchdb1. Otherwise, if we try establishing the membership in the other
  # direction, a race condition in the /etc/hosts entries could lead to couchdb1 not being able to
  # connect to this node.
  #curl -s -x PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb$TASK_SLOT:5986/_nodes/couchdb@couchdb1 -d {}
 # curl -s -x PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb$TASK_SLOT:5984/_nodes/couchdb@couchdb1 -d {}

curl -s -X GET "http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb$TASK_SLOT:5984/_membership"
curl -s -X PUT "http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb$TASK_SLOT:5984/_node/_local/_nodes/couchdb@couchdb1" -d {}
curl -s -X GET "http://$COUCHDB_USER:$COUCHDB_PASSWORD@couchdb$TASK_SLOT:5984/_membership"
fi
