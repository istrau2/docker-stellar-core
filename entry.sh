#!/usr/bin/env bash

DB_INITIALIZED="/data/.db-initialized"

set -ue

function stellar_core_newhist() {
    local ARCHIVE_NAME=$1
    local ARCHIVE_INITIALIZED="/data/.newhist-$ARCHIVE_NAME"

	if [ -f $ARCHIVE_INITIALIZED ]; then
		echo "history archive named $ARCHIVE_NAME is already newed up. continuing on..."
		return 0
	fi

	echo "newing up history archive: $ARCHIVE_NAME..."

	stellar-core --newhist $ARCHIVE_NAME

	echo "newing up history archive: $ARCHIVE_NAME"

	touch $ARCHIVE_INITIALIZED
}

function stellar_core_init_db() {
  local DB_INITIALIZED="/data/.db-initialized"

  if [ -f $DB_INITIALIZED ]; then
    echo "core db already initialized. continuing on..."
    return 0
  fi

  echo "initializing core db..."

  stellar-core --conf /stellar-core.cfg -newdb

  echo "finished initializing core db"

  touch $DB_INITIALIZED
}

confd -onetime -backend env -log-level error

#attempt to init the db (if it does not yet exist)
stellar_core_init_db

#attempt to new any history archives that have not yet been newed.
echo "$HISTORY" | jq -r 'to_entries[] | select(.value | has("put")) | .key' | while read archive_name; do
    stellar_core_newhist $archive_name
done

exec "$@"
