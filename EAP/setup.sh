#!/bin/bash
#
# Copyright 2014-2015 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

for args in "$@"
do
  case $args in
    --setup)
      SETUP=true
    ;;
    --clean)
      CLEAN=true
    ;;
    --start)
      START=true
    ;;
    --eap-zip=*)
      EAP_ZIP="${args#*=}"
    ;;
    --resteasy-zip=*)
      RE_ZIP="${args#*=}"
    ;;
  esac
done

if [ -n "$CLEAN" ]; then
  rm -rf EAP
fi

if [ -n "$SETUP" ]; then
  if [ ! -d EAP/jboss-eap-6.4 ]; then

  echo setup $SETUP
  if [ -z "$EAP_ZIP" ]; then
    EAP_ZIP=`pwd`/jboss-eap-6.4.0.zip
  fi
  echo Using EAP zip from location: $EAP_ZIP
 
  mkdir .cache 2> /dev/null 
  if [ ! -f .cache/resteasy-jaxrs.zip ]; then
    if [ -z "$RE_ZIP" ]; then
      echo RestEasy zip not specified and not in the cache, downloading.
      wget http://iweb.dl.sourceforge.net/project/resteasy/Resteasy%20JAX-RS/3.0.9.Final/resteasy-jaxrs-3.0.9.Final-all.zip --directory-prefix=.cache -O .cache/resteasy-jaxrs.zip
    else
      cp $RE_ZIP .cache/resteasy-jaxrs.zip
    fi
  fi

  if [ ! -d .cache/resteasy-jaxrs-3.0.9.Final ]; then
    unzip -q -o .cache/resteasy-jaxrs.zip -d .cache
  fi

  RE_ZIP=.cache/resteasy-jaxrs.zip

  mkdir EAP 2> /dev/null
  cp $EAP_ZIP EAP
  unzip -q EAP/*.zip -d EAP

  cp .cache/resteasy-jaxrs-3.0.9.Final/resteasy-jboss-modules-3.0.9.Final.zip EAP/jboss-eap-6.4/modules/system/layers/base
  pushd .
  cd EAP/jboss-eap-6.4/modules/system/layers/base 
  unzip -q -o resteasy-jboss-modules-3.0.9.Final.zip
  popd
   
  else
    echo "The ./EAP/jboss-eap-6.4 directory already exists. Cannot perform setup. Please clean the project first"
  fi

elif [ -n "$START" ]; then
  echo start $START
  ./EAP/jboss-eap-6.4/bin/standalone.sh
else
  echo unknown option
fi
