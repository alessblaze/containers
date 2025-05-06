#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "                   ###                   "
echo "              +###########*              "
echo "           #####################         "
echo "     #########   #######   #########     "
echo " ########  ###   ######    ###  ######## "
echo " ####      ###    #####    ###      #### "
echo " ####      ###    #####    ###      #### "
echo " ####  ##  ###    ####     ###   ####### "
echo " ####  #*  ###     ###     ###   ####### "
echo " ####  ##  ###     ###     ###   ####### "
echo " ####      ###     ###     ###      #### "
echo " ####      ###      #      ###      #### "
echo " ####  ##  ###      #      ######   #### "
echo " ####  ##  ###      #  #   ######   #### "
echo " ####  ##  ###   #     #   ######   #### "
echo " ####  ##  ###   #    ##   ###      #### "
echo " ####  ##  ###   ##   ##   ###      #### "
echo " ######### ###   ##  ###   ###  ######## "
echo "     ##########  ### ###   #########     "
echo "          #####################          "
echo "              *###########*              "
echo "                   ###                   "
echo "-----------------------------------------"
echo "  Aless Microsystems Extended Container  "
echo "-----------------------------------------"
echo "Logs begin from Existing Bitnami scripts with extended functionality"
echo "** Starting supervisord as entrypoint **" 

# Replace shell with supervisord (important for signal forwarding)
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
