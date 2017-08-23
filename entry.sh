#!/usr/bin/env bash

DB_INITIALIZED="/data/.db-initialized"

set -ue

function stellar_core_newhist() {
    archive_name=$1

	if [ -f "/data/.newhist-$archive_name" ]; then
		echo "history archive named $archive_name is already newed up.";
		return 0;
	fi

	echo "newing up history archive: $archive_name...";

	stellar-core --newhist $archive_name;

	echo "newing up history archive: $archive_name";

	touch "/data/.newhist-$archive_name";
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
