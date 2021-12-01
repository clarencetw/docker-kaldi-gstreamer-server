#!/bin/bash

MASTER="localhost"
PORT=80
MODEL="master"

usage(){
  echo "Creates a worker and connects it to a master.";
  echo "If the master address is not given, a master will be created at localhost:80";
  echo "Create master server use -o master. Create worker use -o worker";
  echo "Usage: $0 -o master | worker -y yaml_file [-m master address] [-p port number]";
}

while getopts "h?m:p:y:o:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    m)  MASTER=$OPTARG
        ;;
    p)  PORT=$OPTARG
        ;;
    y)  YAML=$OPTARG
        ;;
    o)  MODEL=$OPTARG
        ;;
    esac
done

#yaml file must be specified
if [ "$MODEL" == "worker" ] && ([ -z "$YAML" ] || [ ! -f "$YAML" ]) ; then
  usage;
  exit 1;
fi;


if [ "$MODEL" == "master" ] ; then
  # start a local master
  python /opt/kaldi-gstreamer-server/kaldigstserver/master_server.py --port=$PORT | while read line; do echo "[master] $line"; done
else
  #start worker and connect it to the master
  export GST_PLUGIN_PATH=/opt/gst-kaldi-nnet2-online/src/:/opt/kaldi/src/gst-plugin/
  export LD_PRELOAD=/opt/intel/mkl/lib/intel64/libmkl_core.so:/opt/intel/mkl/lib/intel64/libmkl_sequential.so:/opt/intel/mkl/lib/intel64/libmkl_rt.so

  python /opt/kaldi-gstreamer-server/kaldigstserver/worker.py -c $YAML -u ws://$MASTER:$PORT/worker/ws/speech | while read line; do echo "[worker] $line"; done
fi
