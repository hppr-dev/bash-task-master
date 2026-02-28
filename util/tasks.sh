task_spec release "Build a new release" "version:v:nowhite" ""

task_release() {
  cd "$TASK_DIR" || exit
  
  echo "Building assets for btm version $ARG_VERSION..."

  mkdir dist
  
  cat > version.env << EOF
BTM_ASSET_URL=https://github.com/hppr-dev/bash-task-master/releases
BTM_VERSION=$ARG_VERSION
EOF
  
  cp -r ../lib ../awk ../task-runner.sh ../LICENSE.md ../config.env dist
  
  tar -czf btm.tar.gz dist
}
