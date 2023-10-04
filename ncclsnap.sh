#!/bin/bash
echo "+-----------------------+"
echo "|  ncclsnap v0.1        |"
echo "+-----------------------+"
echo ""

num_args=$#

verbose_mode=0
if [ "$num_args" -gt 0 ]; then
	if [ "$1" == "-v" ]; then
		verbose_mode=1
	else
		echo "Usage: ncclsnap.sh [-v]"
		echo "-v	Verbose"
		echo ""
	fi
fi

## Detect number of NUMA nodes
lscpu | grep -i numa | awk '/NUMA node\(s\)/ {print "-> Number of NUMA node(s): "$NF}'
## Will also show "NUMA node0 CPU(s):  ...  0-47"
## What will it show with multiple numa nodes? [todo]
## Show which CPUs belong to which NUMA nodes [todo]

## Detect number of NVIDIA devices (these should only be GPUs within AWS -- right?)

num_gpus=$(lspci | grep -i nvidia | wc -l)
if [ "$num_gpus" -gt 0 ]; then
	echo "-> Number of detected GPU(s): $num_gpus"
	if [ "$verbose_mode" == 1 ]; then
		count=0
		lspci | grep -i nvidia | while read -r line; do
		device=$(echo "$line") # | awk -F': ' '{print $6}')
		    echo "  $((++count))) $device"
		done
	fi
else
	echo "* -> Number of detected GPU(s): $num_gpus"
fi

## Check if NVIDIA driver is installed
echo -n "-> NVIDIA driver detected: "
dpkg -l | grep -i nvidia-driver- | awk '/nvidia-driver-/ {print $3; found=1; exit} END {if (!found) print "None"}'

## Check for CUDA and version
installed_package=$(sudo dpkg --get-selections | grep -w "install" | egrep -i 'cuda-(12|11|10|9)' | awk '{print $1}')
if [ -n "$installed_package" ]; then
    cuda_version=$(sudo dpkg -l $installed_package | awk 'NR==6 {print $3}')
    echo "-> CUDA version installed: $cuda_version"
else
    echo "* -> CUDA version installed: None."
fi

## Check for OpenCL and version
installed_package=$(sudo dpkg --get-selections | grep -w "install" | egrep -i 'cuda-opencl-(12|11|10|9)' | awk '{print $1}')
if [ -n "$installed_package" ]; then
    opencl_version=$(sudo dpkg -l $installed_package | awk 'NR==6 {print $3}')
    echo "-> OpenCL version installed: $opencl_version"
else
    echo "* -> OpenCL version installed: None."
fi

## Check for EFA installed
# fi_info comes from libfabric and libfabric should be installed with the EFA installer
if command -v fi_info &> /dev/null; then
    echo "-> EFA/LibFabric detected."
else
    echo "* -> EFA/LibFabric not installed."
fi

## Check if MPI is installed
if command -v ompi_info &> /dev/null; then
		version=$(dpkg -s openmpi40-aws | grep "Version:" | awk '{print $2}')
		echo "-> MPI version $version is installed."
else
        echo "* -> MPI is not installed."
fi

## Check if AWS OFI NCCL is installed
check_ofi_dir=$HOME/aws-ofi-nccl/install/lib
if [ -d "$check_ofi_dir" ]; then
        echo "-> AWS OFI NCCL is installed."
else
        echo "* -> AWS OFI NCCL is NOT installed."
fi
## Find version installed and display it if it exists [todo]

## Check if NCCL is installed
echo -n "-> NCCL library detected: "
dpkg -l | grep -i libnccl2 | awk '/libnccl2/ {print $3; found=1; exit} END {if (!found) print "None."}'

## Check if NCCL-tests is installed
check_nccl_dir=$HOME/nccl-tests
check_nccl_install=$HOME/nccl-tests/build/all_reduce_perf
if [ -d "$check_nccl_dir" ]; then
        if [ -f "$check_nccl_install" ]; then
                echo "-> NCCL-tests installed and compiled."
        else
                echo "* -> NCCL-tests installed but NOT compiled."
        fi
else
        echo "* -> NCCL-tests not installed."
fi

## Detect and show fabric manager & version

## Detect/show CuDNN

## Detect/show GDRCopy

## Slurm

## Docker

## Support utils installed? cmake, unzip, g++, libhwloc-dev, etc.


