# FAST-LIVO2 to HDMapping simplified instruction

## Step 1 (prepare data)
Download the dataset `reg-1.bag` by clicking [link](https://cloud.cylab.be/public.php/dav/files/7PgyjbM2CBcakN5/reg-1.bag) (it is part of [Bunker DVI Dataset](https://charleshamesse.github.io/bunker-dvi-dataset)).

File 'reg-1.bag' is an input for further calculations.
It should be located in '~/hdmapping-benchmark/data'.


## Step 2 (prepare docker)
Clone the FAST-LIVO2 source into the `src/` directory before building:
```shell
mkdir -p ~/hdmapping-benchmark
cd ~/hdmapping-benchmark
git clone https://github.com/MapsHD/benchmark-fast-livo2-to-HDMapping.git --recursive
cd benchmark-fast-livo2-to-HDMapping
cd src
git clone https://github.com/hku-mars/FAST-LIVO2.git fast-livo2
cd ..
docker build -t fast-livo2_noetic .
```

## Step 3 (run docker, file 'reg-1.bag' should be in '~/hdmapping-benchmark/data')
```shell
cd ~/hdmapping-benchmark/benchmark-fast-livo2-to-HDMapping
chmod +x docker_session_run-ros1-fast-livo2.sh
cd ~/hdmapping-benchmark/data
~/hdmapping-benchmark/benchmark-fast-livo2-to-HDMapping/docker_session_run-ros1-fast-livo2.sh reg-1.bag .
```

## Step 4 (Open and visualize data)
Expected data should appear in ~/hdmapping-benchmark/data/output_hdmapping-fast-livo2
Use tool [multi_view_tls_registration_step_2](https://github.com/MapsHD/HDMapping) to open session.json from ~/hdmapping-benchmark/data/output_hdmapping-fast-livo2.

You should see following data in '~/hdmapping-benchmark/data/output_hdmapping-fast-livo2'

fast_livo2_initial_poses.reg

poses.reg

scan_fast_livo2_*.laz

session.json

trajectory_fast_livo2_*.csv

## Contact email
januszbedkowski@gmail.com
