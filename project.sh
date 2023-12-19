#!/bin/bash

# Hello. This is "./project.sh".
# A wrapper for creating a C project from scratch.
# I really like "cargo new" command in Rust and I wanted to
# create a similar bootstrapper.
#
# Note: This is my first proper Bash script.
#
# Enjoy!

PROJECT_SH_VERSION="0.0.1"

IS_PROJECT_CXX=${IS_PROJECT_CXX:-0}

create_project_directories () {
  mkdir -p include src
  if [[ $? -ne 0 ]]; then
    echo "Creating subdirectories failed."
    popd
    exit 255
  fi
}

create_project_files () {
  touch include/$1.h

  INITIAL_INCLUDE_GUARD="${PROJECT_NAME^^}_${PROJECT_NAME^^}_H"

  echo -e "#ifndef ${INITIAL_INCLUDE_GUARD}\n#define ${INITIAL_INCLUDE_GUARD}\n#endif" >> include/$1.h

  if [[ $IS_PROJECT_CXX -eq 1 ]]; then
    touch src/$1.cpp
    echo -e '#include "'$1'.h"\n\nint main(int argc, char **argv) {\n\tputs("Hello '$1'!");\nreturn 0;\n}\n' >> src/$1.cpp
  else
    touch src/$1.c
    echo -e '#include "'$1'.h"\n\nint main(int argc, char **argv) {\n\tputs("Hello '$1'!");\n\treturn 0;\n}\n' >> src/$1.c
  fi
}

create_project_sources () {
  touch CMakeLists.txt

  echo "cmake_minimum_required(VERSION 3.20)" >> CMakeLists.txt
  echo -e "project($1)\n" >> CMakeLists.txt

  echo "include_directories(include)" >> CMakeLists.txt

  if [[ $IS_PROJECT_CXX -eq 1 ]]; then
    echo "add_executable($1 src/$1.cpp)" >> CMakeLists.txt
  else
    echo "add_executable($1 src/$1.c)" >> CMakeLists.txt
  fi
}

create_project () {
  PROJECT_NAME=$1

  mkdir $PROJECT_NAME

  if [[ $? -ne 0 ]]; then
    # Check if "configure" is called, if it is, ignore "creating failed error"
    echo 'Creating directory failed. Most probably it already exists.'
    exit 255
  fi

  pushd $PWD/$PROJECT_NAME

  # First, let's create our directories.

  create_project_directories $PROJECT_NAME
  create_project_files $PROJECT_NAME
  create_project_sources $PROJECT_NAME

  popd
}


configure () {

  PROJECT_NAME=$1
  BUILD_FOLDER_NAME="build"
  CMAKE_PROJECT_GENERATOR="Ninja"

  if ! command -v cmake &> /dev/null; then
    echo "cmake could not be found."
    return 255
  fi

  cmake \
    -B $PWD/$PROJECT_NAME/$BUILD_FOLDER_NAME \
    -G $CMAKE_PROJECT_GENERATOR \
    -S $PWD/$PROJECT_NAME

  if [[ $? -ne 0 ]]; then
    echo "CMake generate failed."
    return 255
  fi

  return 0
}

echo "./project.sh $PROJECT_SH_VERSION"

IS_ONLY_CONFIGURE=0

if [[ "$#" -ge 2 ]]; then
  # It is a project.sh command! Let's parse it.
  case $2 in
    configure)
      IS_ONLY_CONFIGURE=1
      configure $1
      ;;

    *)
      # create_project $PROJECT_NAME
      echo "Command $2 not found."
      ;;
  esac
elif [ -n "$1" ]; then
  PROJECT_NAME=$1
  create_project $PROJECT_NAME
else
  echo "No project name supplied."
  exit 255
fi

exit 0
