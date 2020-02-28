BIN_DIR=${BIN_DIR:-$(cd "${1%/*}"&&pwd)}

# src env for contract deployment
source ./bin/util.sh
source ./bin/test/local_env.sh

# create address file and build contracts
touch ./bin/test/addresses.json

dapp update && dapp build --extract

export ACTIONS=$(seth send --create ./out/Actions.bin 'Actions()')
message Tinlake Actions Address: $ACTIONS

DEPLOYMENT_FILE=$BIN_DIR/bin/test/addresses.json

addValuesToFile $DEPLOYMENT_FILE <<EOF
{
    "ACTIONS" :"$ACTIONS"
}
EOF

