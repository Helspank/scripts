#!/bin/zsh

# Check if correct number of arguments is provided
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <video_file> <tsv_file> <output_directory>"
  exit 1
fi

# Function to convert timestamp to seconds
timestamp_to_seconds() {
  local h=$(echo $1 | cut -d':' -f1)
  local m=$(echo $1 | cut -d':' -f2)
  local s=$(echo $1 | cut -d':' -f3)
  bc <<< "scale=3; ($h * 3600) + ($m * 60) + $s"
}

video_file="$1"
tsv_file="$2"
output_dir="$3"

# Check if input files exist
if [[ ! -f "$video_file" ]]; then
  echo "Video file not found: $video_file"
  exit 1
fi

if [[ ! -f "$tsv_file" ]]; then
  echo "TSV file not found: $tsv_file"
  exit 1
fi

# Check if output directory exists or create it
if [[ ! -d "$output_dir" ]]; then
  mkdir -p "$output_dir"
fi

# Get the filename without extension
filename=$(basename "$video_file")
filename="${filename%.*}"

# Read the TSV file and store segments in an array
segments=()
while IFS=$'\t' read -r start_timestamp end_timestamp; do
  start_seconds=$(timestamp_to_seconds "$start_timestamp")
  end_seconds=$(timestamp_to_seconds "$end_timestamp")
  segments+=("$start_seconds $end_seconds")
done < "$tsv_file"

# Process each segment
for ((i = 1; i <= ${#segments[@]}; i++)); do
  segment="${segments[$i]}"
  start_seconds=$(echo "$segment" | cut -d' ' -f1)
  end_seconds=$(echo "$segment" | cut -d' ' -f2)

  ffmpeg -ss "$start_seconds" -to "$end_seconds" -i "$video_file" -vf "fps=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$video_file")" -c:v libwebp -quality 90 "${output_dir}/${filename}_${i}_%06d.webp"
done
