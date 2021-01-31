#!/bin/bash

set -e

if [ "$COUCHDB_DATA_DIR" ]; then
  # Create a symbolic link to the CouchDB data so that we can prefix it with the service name and
  # task slot
  rm -rf /opt/couchdb/data

  # Make sure directory exists
  mkdir -p $COUCHDB_DATA_DIR

  ln -s $COUCHDB_DATA_DIR /opt/couchdb/data
fi

# Use sname so that we can specify a short name, like those used by docker, instead of a host
if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
  # A cookie is needed so that the nodes can connect to each other using Erlang clustering
  if [ -z "$COUCHDB_COOKIE" ]; then
    echo "-sname couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
  else
    echo "-sname couchdb@$NODENAME -setcookie '$COUCHDB_COOKIE'" >> /opt/couchdb/etc/vm.args
  fi
fi

if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ] && [ -z "$COUCHDB_HASHED_PASSWORD" ]; then
  # Create admin
  printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" >> /opt/couchdb/etc/local.d/docker.ini
fi

if [ "$COUCHDB_USER" ] && [ "$COUCHDB_HASHED_PASSWORD" ]; then
  # Create the admin using the hashed password. As per https://stackoverflow.com/q/43958527/2831606
  # we need all nodes to have the exact same password hash.
  printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_HASHED_PASSWORD" > /opt/couchdb/etc/local.d/docker.ini
fi

if [ "$COUCHDB_SECRET" ]; then
  # Set secret
  printf "[couch_httpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> /opt/couchdb/etc/local.d/docker.ini
fi

if [ "$COUCHDB_CERT_FILE" ] && [ "$COUCHDB_KEY_FILE" ] && [ "$COUCHDB_CACERT_FILE" ]; then
  # Enable SSL
  printf "[daemons]\nhttpsd = {chttpd, start_link, [https]}\n\n" >> /opt/couchdb/etc/local.d/docker.ini
  printf "[ssl]\ncert_file = %s\nkey_file = %s\ncacert_file = %s\n" "$COUCHDB_CERT_FILE" "$COUCHDB_KEY_FILE" "$COUCHDB_CACERT_FILE" >> /opt/couchdb/etc/local.d/docker.ini

  # As per https://groups.google.com/forum/#!topic/couchdb-user-archive/cBrZ25DHHVA, due to bug
  # https://issues.apache.org/jira/browse/COUCHDB-3162, we need the following lines. TODO: remove
  # this in a later version of CouchDB 2.
  printf "ciphers = undefined\ntls_versions = undefined\nsecure_renegotiate = undefined\n" >> /opt/couchdb/etc/local.d/docker.ini
fi

# Set the permissions. This is not needed as we are running couchdb as root
# if [ -f /opt/couchdb/etc/local.d/docker.ini ];
#   chown couchdb:couchdb /opt/couchdb/etc/local.d/docker.ini
# fi

if [ "$COUCHDB_LOCAL_INI" ]; then
  # If a custom local.ini file is specified, e.g. through a volume, then copy it to CouchDB
  cp $COUCHDB_LOCAL_INI /opt/couchdb/etc/local.d/local.ini
fi

/opt/couchdb/bin/couchdb
# /opt/couchdb/bin/couchdb 1>/dev/stdout 2>/dev/stderr
