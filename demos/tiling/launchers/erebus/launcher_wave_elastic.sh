#!/bin/bash

rm -rf /data/output/

OPTS="--output 100 --flatten True"
TILE_OPTS="--extra-halo 1 --fusion-mode only_tile"

export OMP_NUM_THREADS=1
export SLOPE_BACKEND=SEQUENTIAL

for poly in 1 2 3
do
    output_file="output_p"$poly".txt"
    echo "Polynomial order "$poly
    for MESH in "--mesh-size (300.0,150.0,0.8)"
    do
        rm -f $output_file
        touch $output_file
        echo "    Running "$MESH
        for p in "chunk" "metis"
        do
            echo "        Untiled ..."
            mpirun --bind-to-core -np 4 python wave_elastic.py --poly-order $poly $MESH $OPTS --num-unroll 0 --part-mode $p 1>> $output_file 2>> $output_file
            for sm in 4
            do
                for ts in 40 70 150 300
                do
                    echo "        Tiled (pm="$p", ts="$ts") ..."
                    mpirun --bind-to-core -np 4 python wave_elastic.py --poly-order $poly $MESH $OPTS --num-unroll 1 --tile-size $ts --part-mode $p --split-mode $sm $TILE_OPTS 1>> $output_file 2>> $output_file
                done
            done
        done
    done
done

export OMP_NUM_THREADS=4
export KMP_AFFINITY=scatter
export SLOPE_BACKEND=OMP
echo "No OMP experiments set"