# Stellar Core Docker image

## Configuration

The container can be fully configured via environment variables.

### Create node seed

If you don't have a node seed yet you can create one by running
```
docker run --rm -it stellar-core stellar-core --genseed
```
Use the *Secret seed* **only** for the `NODE_SEED` env variable and tell other nodes
your *Public* key.

### Environment variables

All Stellar Core config options can be set via environment variables. Here we list the
ones you probably want to set:

* `NODE_SEED`: your secret seed, see above.

* `NETWORK_PASSPHRASE`: default is `Public Global Stellar Network ; September 2015` which
  is the public production network; use `Test SDF Network ; September 2015` for the testnet.

* `DATABASE`: default is `sqlite3://stellar.db` which you should definitely change for production,
   e.g., `postgresql://dbname=stellar user=postgres host=postgres`.

* `KNOWN_PEERS`: comma-separated list of peers (`ip:port`) to connect to when
   below *TARGET_PEER_CONNECTIONS*, e.g.,
   `core-live-a.stellar.org:11625,core-live-b.stellar.org:11625,core-live-c.stellar.org:11625`.

* `HISTORY`: JSON of the following form:
   ```
   {
     "h1": {
       "get": "curl -sf http://history.stellar.org/prd/core-live/core_live_001/{0} -o {1}"
     }
   }
   ```
* `NODE_NAMES`: comma-separated list of nodes with names (e.g., for using them in `QUORUM_SET`), for example:
   ```
   GCGB2S2KGYARPVIA37HYZXVRM2YZUEXA6S33ZU5BUDC6THSB62LZSTYH  sdf_watcher1,GCM6QMP3DLRPTAZW2UZPCPX2LF3SXWXKPMP3GKFZBDSF3QZGV2G5QSTK  sdf_watcher2,GABMKJM6I25XI4K7U6XWMULOUQIQ27BCTMLS6BYYSOWKTBUXVRJSXHYQ  sdf_watcher3

   ```

* `QUORUM_SET`: JSON of the following form:
   ```
   [
     {
       "validators": [
         "GDQWITFJLZ5HT6JCOXYEVV5VFD6FTLAKJAUDKHAV3HKYGVJWA2DPYSQV you_can_add",
         "GANLKVE4WOTE75MJS6FQ73CL65TSPYYMFZKC4VDEZ45LGQRCATGAIGIA human_readable"
        ]
     },
     {
       "path": "1",
       "threshold_percent": 67,
       "validators": [
         "$self",
         "GDXJAZZJ3H5MJGR6PDQX3JHRREAVYNCVM7FJYGLZJKEHQV2ZXEUO5SX2 some_name"
       ]
     }
   ]
   ```

### AWS History Archive
To use aws as archive destination, add a history destination of the following form:
```
   {
     "h2": {
       "get": "curl http://history.stellar.org/{0} -o {1}",
       "put": "aws s3 cp {0} s3://history.stellar.org/{1}"
     }
   }
```
In order for this to work you must include an AWS section in your config with a mimimum of aws_access_key_id and aws_secret_access_key.


### Sample Output
```
version: '3'
services:
  postgres-core:
    image: postgres:9
    volumes:
      - "/var/stellar-data-testnet/postgres-core:/var/lib/postgresql/data"
    environment:
      - POSTGRES_DB=stellar-core
  stellar-core:
    image: stellar-core
    restart: always
    links:
      - postgres-core
    ports:
      # peer port
      - "11625:11625"
    volumes:
      - "/var/stellar-data-testnet/core:/data"
    environment:
      - DATABASE=postgresql://dbname=stellar-core user=postgres host=postgres-core
      - NODE_SEED=XXXXX
      - PUBLIC_SEED=XXXXX
      - KNOWN_PEERS=core-testnet1.stellar.org,core-testnet2.stellar.org,core-testnet3.stellar.org
      - NETWORK_PASSPHRASE=Test SDF Network ; September 2015
      - UNSAFE_QUORUM=true
      - FAILURE_SAFETY=1
      - CATCHUP_RECENT=60480
      - >-
          NODE_NAMES=
          GDKXE2OZMJIPOSLNA6N6F2BVCI3O777I2OOC4BV7VOYUEHYX7RTRYA7Y sdf1,
          GCUCJTIYXSOXKBSNFGNFWW5MUQ54HKRPGJUTQFJ5RQXZXNOLNXYDHRAP sdf2,
          GC2V2EFSXN6SQTWVYA5EPJPBWWIMSD2XQNKUOHGEKB535AQE2I6IXV2Z sdf3
      - >-
          QUORUM_SET=[
            {
              "threshold_percent": 51,
              "validators":["$$sdf1","$$sdf2","$$sdf3"]
            }
          ]
      - >-
          HISTORY={
            "h1": {"get": "curl -sf http://s3-eu-west-1.amazonaws.com/history.stellar.org/prd/core-testnet/core_testnet_001/{0} -o {1}"},
            "h2": {"get": "curl -sf http://s3-eu-west-1.amazonaws.com/history.stellar.org/prd/core-testnet/core_testnet_002/{0} -o {1}"},
            "h3": {"get": "curl -sf http://s3-eu-west-1.amazonaws.com/history.stellar.org/prd/core-testnet/core_testnet_003/{0} -o {1}"},
            "archive": {
              "get": "curl http://lupoex-stellar-archive.s3.amazonaws.com/{0} -o {1}",
              "put": "aws s3 cp {0} s3://lupoex-stellar-archive/{1}"
            }
          }
      - >-
          AWS={
            "aws_access_key_id": "xxx",
            "aws_secret_access_key": "xxx",
            "region": "us-east-2",
            "ouput": "json"
          }
  postgres-horizon:
    image: postgres:9
    volumes:
      - "/var/stellar-data-testnet/postgres-horizon:/var/lib/postgresql/data"
    environment:
      - POSTGRES_DB=stellar-horizon
  stellar-horizon:
    image: stellar-horizon
    restart: always
    links:
      - stellar-core
      - postgres-horizon
      - postgres-core
    ports:
      # HTTP port
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://postgres@postgres-horizon/stellar-horizon?sslmode=disable
      - STELLAR_CORE_DATABASE_URL=postgres://postgres@postgres-core/stellar-core?sslmode=disable
      - STELLAR_CORE_URL=http://stellar-core:11626
      - INGEST=true
```
