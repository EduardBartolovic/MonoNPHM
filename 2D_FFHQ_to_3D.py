import os
import shutil
from mononphm import env_paths


def move_file_to_new_folder(input_dir, output_dir):
    if not os.path.exists(input_dir):
        print(f"The input directory {input_dir} does not exist.")
        return

    os.makedirs(output_dir, exist_ok=True)

    # Iterate over all files in the input directory
    for file_name in os.listdir(input_dir):
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


def apply_pre_processing(working_dir):
    for dir_name in os.listdir(working_dir):
        print(dir_name)
        os.system(f'cd {env_paths.CODE_BASE}/scripts/preprocessing/; bash run.sh {dir_name} --no-intrinsics_provided')


def apply_mononphm(working_dir):
    for dir_name in os.listdir(working_dir):
        print(dir_name)
        os.system(f'python scripts/inference/rec.py --model_type nphm --exp_name pretrained_mononphm --ckpt 2500 --seq_name {dir_name} --no-intrinsics_provided --downsample_factor 0.33')



if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Process input directory for MonoNPHM.")
    parser.add_argument('input_dir', type=str, help="The input directory containing files to process.")
    parser.add_argument('output_dir', type=str, help="The output directory where files will be processed.")

    args = parser.parse_args()

    # Use the provided arguments
    input_dir = args.input_dir
    output_dir = args.output_dir

    # Execute the processing functions
    move_file_to_new_folder(input_dir, output_dir)
    apply_pre_processing(output_dir)
    apply_mononphm(output_dir)