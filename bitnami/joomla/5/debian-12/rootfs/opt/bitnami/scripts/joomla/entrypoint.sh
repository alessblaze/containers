#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Joomla! environment
. /opt/bitnami/scripts/joomla-env.sh

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libwebserver.sh

echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠉⠀⠀⠀⠀⠀⠉⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢀⣼⣿⣿⣿⣿⣿⣷⣶⣾⣿⣿⣷⣦⠀⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢠⡟⣉⣉⠙⠻⣿⣿⠿⠛⠉⢉⡉⠻⣿⣿⡀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢸⡇⢀⡀⠈⢈⣿⣿⡀⠉⣀⣈⣙⠦⢿⣿⡇⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣸⣿⣿⣶⣶⣿⣿⣿⣿⣶⣭⣭⣽⣷⣾⣿⣿⡀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢻⣿⣿⡿⣋⠘⠿⠛⠛⠊⠻⣿⣿⣿⣿⣿⣿⡏⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⢸⣿⡟⠑⠋⠈⠉⠀⠈⠉⠓⢽⣿⣿⣿⣿⡿⣡⡂⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡘⡛⠃⠀⠀⣀⢀⣄⣀⠀⠀⠀⠙⢿⣿⣿⠃⣭⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⢻⣷⣶⣿⣿⣀⣀⣀⣶⣤⣤⣼⣿⣿⣿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠊⢿⡿⣿⣿⡿⢟⡿⣿⣿⣿⡿⢿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠙⢶⣯⣥⣌⠀⢨⣭⣵⣾⣿⡿⠁⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⡿⠿⠟⠛⠉⠅⠀⠀⠀⠀⠀⠀⠙⠻⣿⠀⠸⣿⣿⣿⠟⠁⠀⠀⠀⢙⡛⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⠋⠑⠖⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢤⣀⠙⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠒⠶⠬⠉⠻⣿⣿⣿⣿"
echo "⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠗⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠰⣶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿"
echo "⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣶⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿"
echo "⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣻"
echo "⣿⣿⣿⣷⣶⣶⣶⣤⣤⣤⣄⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣴⣶⣾⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣤⣤⣀⡀⠀⠀⢀⣀⣤⣤⣴⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
echo "-------------------------------------------------------------"
echo "        Aless Microsystems Extended Containers               "
echo "-------------------------------------------------------------"
echo " Kaspersky isn't spyware, I have it installed everywhere,    "
echo " I scan my offsec tools with it.                             "
echo "                                                   -- Stalin "

print_welcome_page

if [[ "$1" = "/opt/bitnami/scripts/$(web_server_type)/run.sh" || "$1" = "/opt/bitnami/scripts/nginx-php-fpm/run.sh" ]]; then
    info "** Starting Joomla! setup **"
    /opt/bitnami/scripts/"$(web_server_type)"/setup.sh
    /opt/bitnami/scripts/php/setup.sh
    /opt/bitnami/scripts/mysql-client/setup.sh
    /opt/bitnami/scripts/joomla/setup.sh
    /post-init.sh
    info "** Joomla! setup finished! **"
fi

echo ""
exec "$@"
