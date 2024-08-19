import os
import shutil
from mononphm import env_paths
import argparse
import subprocess

def move_file_to_new_folder(input_dir, output_dir):
    if not os.path.exists(input_dir):
        print(f"The input directory {input_dir} does not exist.")
        return

    os.makedirs(output_dir, exist_ok=True)

    # Iterate over all files in the input directory
    files = os.listdir(input_dir)
    for file_name in files:
        input_file_path = os.path.join(input_dir, file_name)

        # Skip directories, we are only interested in files
        if not os.path.isfile(input_file_path):
            raise AttributeError('Folder found!')

        # Name of the new directory (same as the file name without extension)
        new_folder_name = os.path.splitext(file_name)[0]

        # Full path of the new directory in the output directory
        new_folder_path = os.path.join(output_dir, new_folder_name)
        new_folder_path_source = os.path.join(output_dir, new_folder_name, 'source')

        try:
            os.makedirs(new_folder_path, exist_ok=True)
            os.makedirs(new_folder_path_source, exist_ok=True)

            # Rename and Move the file into the new directory
            new_file_path = os.path.join(new_folder_path_source, '00000.png')
            shutil.copy(input_file_path, new_file_path)

            print(f"File {file_name} has been moved to {new_folder_path}")

        except Exception as e:
            print(f"An error occurred while processing {file_name}: {e}")

    return files


def apply_pre_processing(dir_name):
        result = subprocess.run(['sh', './scripts/preprocessing/run.sh', dir_name , '--no-intrinsics_provided'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(result.returncode)
        print(result.stdout.decode('UTF-8'))
        print(result.stderr.decode('UTF-8'))


def apply_mononphm(dir_name):
    os.system(f'python scripts/inference/rec.py --model_type nphm --exp_name pretained_monnphm --ckpt 2500 --seq_name {dir_name} --no-intrinsics_provided --downsample_factor 0.33')
    # pretained_monnphm is correct because of spelling error in googledrive files.



if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Process input directory for MonoNPHM.")
    parser.add_argument('input_dir', type=str, help="The input directory containing files to process.")
    parser.add_argument('working_dir', type=str, help="The output directory where files will be processed.")

    args = parser.parse_args()

    # Use the provided arguments
    input_dir = args.input_dir
    working_dir = args.working_dir
    # Execute the processing functions
    #move_file_to_new_folder(input_dir, working_dir)
    print('Moving files done!')
    dirs = os.listdir(working_dir)#.sort()
    print(dirs)
    for i in dirs[0]:
        apply_pre_processing(os.path.join(working_dir, i))
        print('apply_pre_processing done!')
        apply_mononphm(os.path.join(working_dir, i))
        print('apply_mononphm done!')