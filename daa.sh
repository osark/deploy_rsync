#!/bin/bash

DRUSH_ENV="dev"
HELP=0
DEBUG=0

while [[ $# > 0 ]]
do
  key="$1"

  case $key in
    -e|--env)
      HELP=0
      DRUSH_ENV="$2"
      shift
      ;;
    -h|--help)
      HELP=1
      ;;
    --dry-run)
      DEBUG=1
      ;;
  esac
  shift
done

if [ $HELP -gt 0 ]
then
  echo "Developed by ArkDev
  $0 [-h|--help] [-e|--env ENVIRONMENT]

Deploy using drush9 aliases based on environments.
The script will try to find the drush site aliases identified by environment and load all found aliases except for the aliases prefixed with 'live...' used by Acquia cloud live development.

	-e, --env	Choose environment to deploy to its aliases. (Default: $DRUSH_ENV)
	-h, --help	Print this help text.
	--dry-run	Debug the available aliases and their URIs.

Available environments: "
  ls drush/sites/*.site.yml | sed -e 's/drush\/sites\///' -e 's/\.site.yml//'
  exit 0
fi

if [ ! -e "drush/sites/$DRUSH_ENV.site.yml" ]
then
  echo "drush/sites/$DRUSH_ENV.site.yml"
  echo "Environment $DRUSH_ENV doesn't exists.
Check your \`drush/sites\` directory to make sure that drush alias definition exists for this environment."
  exit 1
fi

function drush_alias_deploy(){
  # DRUSH_ALIAS=$1
  # DRUSH_ALIAS_URI=$2
  echo "Drush processing to ${DRUSH_ALIAS_URI}"
  echo "  - $DRUSH_ALIAS Running database updates..."
  drush $DRUSH_ALIAS updb
  echo "  - $DRUSH_ALIAS Running interactive config import..."
  drush $DRUSH_ALIAS  cim sync
  echo "  - $DRUSH_ALIAS Clearning cache..."
  drush $DRUSH_ALIAS cr
  echo "======================================================="
}

ENV_YML="drush/sites/${DRUSH_ENV}.site.yml"
ENV_SITES=($(cat "drush/sites/$DRUSH_ENV.site.yml" | grep -E '^[^: ]*:' | cut -d ":" -f 1 | grep -v live))

for ((i = 0; i < ${#ENV_SITES[@]}; i++))
do
  DRUSH_ALIAS="@$DRUSH_ENV.${ENV_SITES[$i]}";
  NEXT=$(( $i + 1 ))
  DRUSH_ALIAS_URI=$(awk "/^${ENV_SITES[$i]}:/{flag=1;next}/^${ENV_SITES[$NEXT]}:|^live.*:/{flag=0}flag;" $ENV_YML | grep "uri:" | sed 's/.*uri: //')
  if [ $DEBUG -gt 0 ]
  then
    echo "$DRUSH_ALIAS at $DRUSH_ALIAS_URI"
  else
    drush_alias_deploy $DRUSH_ALIAS $DRUSh_ALIAS_URI 
  fi
done

