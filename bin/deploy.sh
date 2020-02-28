BIN_DIR=${BIN_DIR:-$(cd "${0%/*}"&&pwd)}

# src env for contract deployment
source $BIN_DIR/util.sh
source $BIN_DIR/test/local_env.sh

# create address file and build contracts
dapp update && dapp build --extract

export ACTIONS=$(seth send --create ./out/Actions.bin 'Actions()')
message Tinlake Actions Address: $ACTIONS

cd $BIN_DIR
DEPLOYMENT_FILE=../deployments/addresses_$(seth chain).json

touch $DEPLOYMENT_FILE

addValuesToFile $DEPLOYMENT_FILE <<EOF
{
    "ACTIONS" :"$ACTIONS"
}
EOF

