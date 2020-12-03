#!/bin/bash

ENVIRONMENT='dev'
IGNORE_FILE='./rsync.ignore'
CONF_DIR='vcs'
SCP_SRC="."

# Environment Arrays
# 0 => SSH_USER
# 1 => SSH_HOST
# 2 => SSH_PORT
# 3 => SCP_ROOT (Absolute: e.g.: /home/usr/envs/prod)
# 4 => WEB_ROOT (e.g.: web, Site)
# 5 => PHP_BIN (e.g.: /usr/local/bin/php -d memery_limit=512M)
# 6 => PHP_DRUSH
# declare -a prod=('SSH_USER' 'SSH_HOST' 'SSH_PORT' 'SCP_ROOT' 'WEB_ROOT' 'PHP_BIN' 'PHP_DRUSH')
# declare -a dev=('SSH_USER' 'SSH_HOST' 'SSH_PORT' 'SCP_ROOT' 'WEB_ROOT' 'PHP_BIN' 'PHP_DRUSH')
declare -a ENV

# Environment defaults
SSH_PORT=22
WEB_ROOT='.'
PHP_BIN='/usr/bin/php'

HELP=0
RSYNC=1
SSH_ONLY=0
DOWNLOAD=0
OVERRIDE=0
DRUSH_CONFIG_MANAGEMENT=1
DRUPAL_REBUILD_CACHE=1

while [[ $# > 0 ]]
do
key="$1"

case $key in
  -e|--env)
	HELP=0
	ENVIRONMENT="$2"
	shift
  ;;
   -i|--ignore-file)
    IGNORE_FILE="$2"
    shift;;
  -h|--help)
	HELP=1
  ;;
  --no-rsync|-n)
    RSYNC=0
  ;;
  --ssh)
    SSH_ONLY=1
  ;;
  -D|--download)
    DOWNLOAD=1
  ;;
  -y)
    OVERRIDE=1
  ;;
  --no-dcm)
    DRUSH_CONFIG_MANAGEMENT=0
  ;;
  --no-cr)
    $DRUPAL_REBUILD_CACHE=0
  ;;
  --SSH_USER)
    SSH_USER="$2"
    shift
  ;;
  --SSH_HOST)
    SSH_HOST="$2"
    shift
  ;;
  --SSH_PORT)
    SSH_PORT="$2"
    shift
  ;;
  --SCP_ROOT)
    SCP_ROOT="$2"
    shift
  ;;
  --WEB_ROOT)
    WEB_ROOT="$2"
    shift
  ;;
  --PHP_BIN)
    PHP_BIN="$2"
    shift
  ;;
  --PHP_DRUSH)
    PHP_DRUSH="$2"
    shift
  ;;
  --SCP_SRC)
    SCP_SRC="$2"
    shift
  ;;
esac
shift
done


case $ENVIRONMENT in
        inline|i)
    ENV=(${SSH_USER} ${SSH_HOST} ${SSH_PORT} ${SCP_ROOT} ${WEB_ROOT} ${PHP_BIN} ${PHP_DRUSH})
        ;;
	prod|PROD|Prod)
    ENV=(${prod[@]}); # echo ${ENV[0]} @${ENV[1]}:${ENV[3]} -p ${ENV[2]}
	  REMOTE_WD='prod'
	;;
	dev|DEV|Dev)
    ENV=(${dev[@]});  # echo ${ENV[0]} @${ENV[1]}:${ENV[3]} -p ${ENV[2]}
	  REMOTE_WD='dev'
	;;
	*)
	HELP=1
        REMOTE_WD="$ENVIRONMENT"
	;;
esac

if [ $HELP -gt 0 ]
then
  echo "Developed by ArkDev
  $0 [-h|--help] [-e|--env ENVIRONMENT] [-i|--ignore-file IGNORE_FILE]
    (--ssh | [-n|--no-rsync | -D|--download])

Usage: Deploy all updates to server using rsync
	-e, --env		Choose environment to deploy to. (Default: $ENVIRONMENT)
	-h, --help		Print this help
	-i, --ignore-file	Path to rsync ignore file. (Default: $IGNORE_FILE)
	-n, --no-rsync		Skip file transfere, continue to configuration prompt
				directly
	-D, --download  	Download files instead of uploading them. Dosn't work
				if (-n|--no-rsync) option is selected
	-y      		Override interactive question by answering YES.
        --no-dcm		Disable Drush Configuration Management section.
        --no-cr 		Disable Drush Cache Rebuild section.
	--ssh			Connect SSH ONLY!

Environment Variables: Using \`(-e|--env) (i|inline)\`
	--SSH_USER '<username>'
	--SSH_HOST '<domain|IP>'
	--SSH_PORT '<port (default=22)>'
	--SCP_ROOT '</absolute/path/to/project>'
		Absolute path that starts copying the project to. Without / at the end.
	--WEB_ROOT '<root/dir>'
		Relative path to SCP_ROOT without / at the start.
	--PHP_BIN '</absolute/path/to/php (default='/usr/bin/php')>'
	--PHP_DRUSH '</absolute/path/to/drush>'
	--SCP_SRC '<relative/path>'
		Relative path to the local directory to be deployed.

Available Environments:
	dev|DEV			development environment
	prod|PROD		production environment"

  exit 0
fi

REMOTE_PATH=${ENV[3]}

if [ $SSH_ONLY -gt 0 ]
then
  ssh -o PubkeyAuthentication=yes -p ${ENV[2]} -t ${ENV[0]}@${ENV[1]} "cd ${REMOTE_PATH}/${ENV[4]} && exec bash -l "
  exit 0
fi

if [ $RSYNC -gt 0 ]
then
  if [ $DOWNLOAD -gt 0 ]
  then
    ACTION='Downloading from'
    SRC="${ENV[0]}@${ENV[1]}:${ENV[3]}/"
    DST=$SCP_SRC
  else
    ACTION='Deploying to'
    SRC=$SCP_SRC
    DST="${ENV[0]}@${ENV[1]}:${ENV[3]}"
  fi
  echo "> $ACTION $REMOTE_PATH (DRY-RUN)"
  rsync -avzi --del --no-perms -e "ssh -p ${ENV[2]}" $SRC $DST  --exclude-from="$IGNORE_FILE" --no-times --checksum --dry-run
  
  CONT='n'
  
  if [ $OVERRIDE == 0 ]
  then
  	read  -p "> Do you want to continue?[y:N]" CONT
  else
        echo "> Do you want to continue?[y:N] YES"
	CONT="YES"
  fi
  
  case $CONT in
  	Y*|y*)
  	;;
  	*)
  	  exit
  	;;
  esac
  
  rsync -avz --del --no-perms -e "ssh -p ${ENV[2]}" $SRC $DST --exclude-from="$IGNORE_FILE" --no-times --checksum
else
  echo "Using (${ENVIRONMENT}) $REMOTE_PATH:"
fi

if [ $DRUPAL_REBUILD_CACHE == 1]
then
  if [ $OVERRIDE == 0 ]
  then
    read  -p "> Do you want to rebuild cache?[y:N]" CONT
  else
    echo "> Do you want to rebuild cache?[y:N]YES"
    CONT="YES"
  fi
  
  
  case $CONT in
    Y*|y*)
      echo "Rebuilding cache at $REMOTE_PATH:"
      ssh -p ${ENV[2]} "${ENV[0]}@${ENV[1]}" "cd $REMOTE_PATH/${ENV[4]}; ${ENV[@]:5} cr"
      ;;
    *)
    ;;
  esac
fi

if [ $DRUSH_CONFIG_MANAGEMENT == 0 ]
then
  echo "Drush configuration management is disabled."
  echo "Bye Bye."
  exit 0
fi

if [ $OVERRIDE == 0 ]
then
  read -p "> Do you want to import/export/IGNORE "'`'$CONF_DIR'`'" configuration?[i:e:N]" CONT
else
  echo "> Do you want to import/export/IGNORE '$CONF_DIR' configuration?[i:e:N] IMPORT"
  CONT="IMPORT"
fi

case $CONT in
  I*|i*)
    CONF_COMMAND='config-import'
    ;;
  E*|e*)
    CONF_COMMAND='config-export'
    ;;
  *)
    exit
  ;;
esac
echo "Using Configuration Command: $CONF_COMMAND"

ssh -p ${ENV[2]} "${ENV[0]}@${ENV[1]}" "cd $REMOTE_PATH/${ENV[4]}; ${ENV[@]:5} $CONF_COMMAND $CONF_DIR"

