#!/bin/bash
python ./scripts/preprocessing/run_PIPNet.py --seq_name $1
python ./scripts/preprocessing/run_facer.py --seq_name $1
python ./scripts/preprocessing/run_matting_images.py --seq_name $1
python ./scripts/preprocessing/run_MICA.py --seq_name $1
python ./scripts/preprocessing/run_metrical_tracker.py --seq_name $1 $2 #$2 is --intrinsics_proveded or --no-intrinsics_provided
