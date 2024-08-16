FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04

WORKDIR /app

# Install dependencies for Conda and other utilities
RUN apt-get update && apt-get install -y \
    wget \
    git \
    python3 \
    python3-venv \
    libgl1 \
    libglib2.0-0 \
    apt-transport-https \
    libgoogle-perftools-dev \
    bc \
    build-essential \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libxrender1 \
    libsm6 \
    libxext6 \
    bzip2 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

# Add Conda to the PATH environment variable
ENV PATH=/opt/conda/bin:$PATH

# Clone the Git repository
RUN git clone https://github.com/EduardBartolovic/MonoNPHM .

# Create the conda environment based on environment.yml
RUN conda env create -f environment.yml

# Activate the environment
SHELL ["conda", "run", "-n", "mononphm", "/bin/bash", "-c"]

# Install PyTorch with CUDA support
RUN conda install pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch-cuda=11.7 -c pytorch -c nvidia

# Install PyTorch Geometric and helper packages with CUDA support
RUN conda install pyg=*=*cu* -c pyg && \
    pip install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.0+cu117.html

# Install PyTorch3D with CUDA support
RUN conda install -c fvcore -c iopath -c conda-forge fvcore iopath && \
    conda install pytorch3d=0.7.4 -c pytorch3d

# Install insightface via pip after the environment has been created
RUN pip install insightface

# Uninstall the current version of numpy and install a specific version of numpy
RUN pip uninstall -y numpy && \
    pip install numpy==1.23

# Install a specific version of PyOpenGL
RUN pip install pyopengl==3.1.5

RUN pip install gdown

# Install the package in editable mode
RUN pip install -e .

# Run the preprocessing pipeline script
RUN cd src/mononphm/preprocessing && \
    pip install git+https://github.com/FacePerceiver/facer.git@main

# Define build arguments
ARG FLAME_USERNAME
ARG FLAME_PASSWORD

# Export the build arguments as environment variables and run the install script
RUN cd src/mononphm/preprocessing && \
    git clone https://github.com/Zielon/MICA && \
    cd MICA && \
    conda env create -f environment.yml && \
    mkdir -p data && \
    gdown https://drive.google.com/drive/folders/1xFDmNxvsGc2eYlMDvAaybaLVFfM2WCqd -O data/ --folder && \
    cd data/FLAME2020 && \
    unzip FLAME2020.zip -d ./ && \
    rm -rf FLAME2020.zip && \
    cd .. && \
    mkdir -p pretrained/ && \
    wget -O pretrained/mica.tar "https://keeper.mpdl.mpg.de/f/db172dc4bd4f4c0f96de/?dl=1" && \
    mkdir -p ~/.insightface/models/  && \
    wget -O ~/.insightface/models/antelopev2.zip "https://keeper.mpdl.mpg.de/f/2d58b7fed5a74cb5be83/?dl=1"  && \
    unzip ~/.insightface/models/antelopev2.zip -d ~/.insightface/models/antelopev2 && \
    wget -O ~/.insightface/models/buffalo_l.zip "https://keeper.mpdl.mpg.de/f/8faabd353cfc457fa5c5/?dl=1" && \
    unzip ~/.insightface/models/buffalo_l.zip -d ~/.insightface/models/buffalo_l

# Install metrical tracker and replace files
RUN cd src/mononphm/preprocessing && \
    git clone https://github.com/Zielon/metrical-tracker && \
    cd metrical-tracker && \
    conda env create -f environment.yml && \
    mkdir -p data && \
    gdown https://drive.google.com/drive/folders/1xFDmNxvsGc2eYlMDvAaybaLVFfM2WCqd -O data/ --folder && \
    cd data/FLAME2020 && \
    unzip FLAME2020.zip -d ./ && \
    rm -rf FLAME2020.zip && \
    cd .. && \
    gdown https://drive.google.com/drive/folders/1a477MNKEuOXeZL5GwTj6utDv89FpnvqP -O ./ --folder && \
    cd TextureSpace && \
    unzip -o TextureSpace.zip -d ./../FLAME2020/ && \
    rm -rf TextureSpace.zip && \
    cd .. && \
    wget 'https://files.is.tue.mpg.de/tbolkart/FLAME/FLAME_masks.zip' -O './FLAME_masks.zip' --no-check-certificate --continue && \
    unzip -o FLAME_masks.zip -d FLAME2020/ && \
    rm -rf FLAME_masks.zip && \
    wget -O mesh.zip "https://keeper.mpdl.mpg.de/f/f158a430ef754edba5ec/?dl=1" && \
    unzip -o mesh.zip -d ./ && \
    mv ./mesh/* ./ && \
    rm -rf ./mesh && \
    rm -rf mesh.zip

RUN cp src/mononphm/preprocessing/replacement_code/config.py src/mononphm/preprocessing/metrical-tracker/configs/config.py && \
    cp src/mononphm/preprocessing/replacement_code/generate_dataset.py src/mononphm/preprocessing/metrical-tracker/datasets/generate_dataset.py && \
    cp src/mononphm/preprocessing/replacement_code/tracker.py src/mononphm/preprocessing/metrical-tracker/tracker.py

# Install normal predictor
RUN cd src/mononphm/preprocessing && \
    git clone https://github.com/boukhayma/face_normals.git && \
    mkdir face_normals/pretrained_models/

# Install MODNet for image matting
RUN cd src/mononphm/preprocessing && \
    git clone https://github.com/ZHKKKe/MODNet.git

# Install PIPNet
RUN cd src/mononphm/preprocessing && \
    git clone https://github.com/jhb86253817/PIPNet.git && \
    cd PIPNet/FaceBoxesV2/utils && \
    sh make.sh

RUN mkdir src/mononphm/preprocessing/PIPNet/snapshots && \
    gdown https://drive.google.com/drive/folders/1Mc7iYzMTKSRSoo0sxpdzCeySO1x4Wf4y -O src/mononphm/preprocessing/PIPNet/snapshots/ --folder && \
    cd src/mononphm/preprocessing/PIPNet/snapshots/WFLW

RUN gdown https://drive.google.com/file/d/1Nf1ZxeJZJL8Qx9KadcYYyEmmlKhTADxX -O src/mononphm/preprocessing/MODNet/pretrained/

RUN mkdir MONONPHM_EXPERIMENT_DIR && \
    gdown https://drive.google.com/drive/folders/1shwQnL-TBI4vTsKVLOqyQ7B9rQcW9ozW -O MONONPHM_EXPERIMENT_DIR --folder

RUN mkdir dataset_tracking

# Add a VOLUME instruction to specify the external directory that will be mounted
VOLUME ["/ffhq"]

# Command to run the application within the Conda environment
CMD [ "bash" ]
#CMD ["conda", "run", "-n", "mononphm", "python", "2D_FFHQ_to_3D.py", "/ffhq/15000/", "dataset_tracking/" ]