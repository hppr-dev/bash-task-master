task_edit() {
  vim /home/swalker/.task-master/dogfood/tasks.sh
}
# Recorded Task
task_gen-lib-func() {
    pushd `pwd` > /dev/null
    cd /home/swalker/.task-master/dogfood
    cd ..
    grep -h -I -R lib -e ".*()" | sed 's/\(.*\)().*/readonly -f \1/' | grep -v '\$' > lib-functions.sh
    echo >> lib-functions.sh
    grep -h -I global.sh -e ".*()" | sed 's/\(.*\)().*/readonly -f \1/' | grep -v '\$' | grep -v 'task_edit' >> lib-functions.sh
    popd > /dev/null
}
