declare -A TASK_DRIVER_DICT
declare -A TASK_FILE_NAME_DICT

TASK_FILE_NAME_DICT[tasks.sh]=bash
TASK_FILE_NAME_DICT[.tasks.sh]=bash

TASK_DRIVER_DICT[bash]=bash_driver.sh

source $TASK_MASTER_HOME/lib/drivers/installed_drivers.sh
