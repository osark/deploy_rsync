# rsync Deploy Script for D8

Deploy and manage D8 projects using ssh and rsync.  
The script can rebuild cache of the remote drupal 8 site, import/export drupal 8 configuration, upload and download project files using `rsync`, and access the environments using SSH.

## Prerequisite

* SSH Access (private/public keys)
* `rsync` demon on both dev and server machines
* Drush on server to rebuild drupal cache and import/export configurations

## Configuration

Deployment script must be configured per each project to work properly. There are two main configuration parts:

1. Environment configuration arrays at the start of `deploy_rsync.sh` script.
2. _rsync_ list of ignored files at `rsync.ignore`

### 1. Environment Arrays

At the beginning of the deploy script, you'll find two _bash_ arrays commented. Each one represent a different deployment environment: _prod_ and _dev_.  
Each array has different paramters required for `ssh` and `rsync` commands. Detail list of parameters can be found in the comments above the array definition.

### 2. Rsync Ignore List

The script uses `rsync.ignore` file to be ignored during uploading and downloading. The ignore file should have files to be ignored when uploading; ignore `vendor` and `default/fiels` folders is common configuration. Depending on the live server, it might be required to add several entries per project to ignore them during downloading.

## Usage

Use help flags `-h` or `--help` to display the internal script help for details of different paramters and flags used by the script.

# Drush Alias Actions

If you deploy your Drupal code using git, for example on Acquia, you need to run regular Drush actions post deployment, like updating the database, importing configuration and clear the cache.

Use `./daa.sh` to do these actions dynamically using available Drush aliases dynamically. This is extremelly useful for Drupal multisite setup on the same enviornment, so you can create a `dev`, `stage` and `prod` site aliases, each alias site can have entries for the different subsites available on that environment, and the script will loap over each entry in the Drush alias site and perform the 3 actions in sequence.
