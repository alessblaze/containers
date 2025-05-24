#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

# Load libraries
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libfile.sh

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

cat << 'EOF' >> /etc/profile.d/system-info.sh
echo "        ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠋⠉⠉⠉⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⠿⠋⠁⢀⡠⢆⡖⢢⠆⡄⢀⠀⠀⠀⠈⠙⠻⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⠃⠀⠀⣰⣯⣽⣳⣎⢇⡚⢄⢃⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣇⠀⠀⢰⣟⣾⣿⡙⣿⣮⡕⡊⠄⠂⠀⠀⠀⠀⠀⠀⣽⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣄⢀⢃⣠⠄⠀⣙⡊⠀⡀⠀⠀⠁⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⢨⣋⠤⠀⢀⣌⡗⠀⢄⠤⠀⢀⡀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⢸⢿⣽⣶⠛⣹⡍⠀⢲⡜⡲⠧⠀⠀⠀⢀⢸⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⠨⢧⠛⢀⣌⢀⠀⠀⠀⠹⢣⠑⠈⠀⠀⠈⢸⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⡇⡋⡀⠾⠙⠋⠘⠂⠂⠀⠡⠈⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⣿⡰⡉⢰⣆⠈⣀⠀⠀⠄⡃⠀⠌⠀⠰⣿⣿⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⣿⣿⣿⣿⣷⠔⠙⢏⡛⠤⡘⠁⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿      "
echo "        ⣿⣿⣿⣿⡿⠿⢛⠫⠁⠆⡀⠄⠀⠀⠀⠀⡀⠐⡀⡡⠂⠀⠀⠉⠻⢿⣿⣿⣿⣿      "
echo "        ⢯⠹⣉⠒⠤⢑⡈⠆⠡⠘⢔⢍⠐⡀⠀⠄⠀⠅⠊⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⠿      "
echo "        ⣆⢓⠬⡘⢆⠢⡐⢂⠡⡉⠄⠂⡕⠀⠔⠊⠀⠀⢀⠀⠀⠀⠀⠀⠀⡀⢠⠠⠐⠤      "
echo "        ⢬⡉⢦⠱⣈⠰⡁⢆⡐⡈⠌⢡⠈⠀⠀⠠⠈⠔⡈⠔⠁⠀⡄⠄⠒⢠⠁⠎⢡⠓      "
echo "        ⠆⡜⡠⠓⠤⠑⡈⠆⡄⠘⡈⠄⠀⠀⠀⢀⠁⠐⠀⠀⠀⡁⠐⡈⠅⠢⠑⠌⠢⣉      "
echo "        ⢣⠐⡡⢉⠆⠡⠘⡐⠄⢂⠁⠀⣀⠐⢠⠀⡀⠀⠀⢀⠂⠀⡁⠀⠌⠠⠁⠈⠥⡐      "
echo "        ⠆⡑⠐⠢⡈⢂⠡⠐⡈⢀⠂⠅⠠⠌⢂⠡⠐⠀⠀⠂⠀⠁⠀⡐⠈⠄⠀⠈⠤⠑      "
echo "----------------------------------------------------------"
echo "          Aless Microsystems extended Containers       "
echo "----------------------------------------------------------"
echo "This container was made possible by unlimited opportunities,"
echo "provided by Leader Mao Who single handedly backports all the"
echo "bugfixes from Western repos for a set of thousand packages."
echo "So you must see this message for Leader Mao to know that, "
echo "He is watching you." 
echo "----------------------------------------------------------"
EOF


if [[ "$(get_os_metadata --id)" == "photon" ]]; then
    append_file_after_last_match "/etc/ssl/openssl.cnf" "openssl_conf = openssl_init" "nodejs_conf = openssl_init"
fi

                      
