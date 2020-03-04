ACTIONS_BIN_DIR=${ACTIONS_BIN_DIR:-$(cd "${0%/*}"&&pwd)}

# src env for contract deployment
source $ACTIONS_BIN_DIR/util.sh
source $ACTIONS_BIN_DIR/test/local_env.sh

# create address file and build contracts
dapp update && dapp build --extract

# create deployment folder
mkdir $ACTIONS_BIN_DIR/../deployments

export ACTIONS=$(seth send --create ./out/Actions.bin 'Actions()')
message Tinlake Actions Address: $ACTIONS

cd $ACTIONS_BIN_DIR
DEPLOYMENT_FILE=$ACTIONS_BIN_DIR../deployments/addresses_$(seth chain).json

touch $DEPLOYMENT_FILE

addValuesToFile $DEPLOYMENT_FILE <<EOF
{
    "ACTIONS" :"$ACTIONS"
}
EOF

