#!/bin/bash
# copy and clean up if needed

sed -i -e 's/\r$//' ["$PROJECT_PATH/common/menu/menu_setup2.sh", "$PROJECT_PATH/common/scripts/vagrant_copy.sh"]

