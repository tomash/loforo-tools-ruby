LOFORO_ENDPOINT = "https://loforo.com/api/post/create"

require "./loforo_lib"
require "fileutils"
require "json"

dir_path = ARGV[0]

if(dir_path.nil? || !File.exist?(dir_path) || !File.directory?(dir_path))
  abort "need valid path to media directory"
else
  puts "#{dir_path} ..."
end

# 1. make the uploaded directory

uploaded_dir = File.join(dir_path, "uploaded")
FileUtils.mkdir_p(uploaded_dir)
uploaded = []

# 2. find media files and iterate over them

file_paths = Dir.glob(dir_path+"/*.{jpg,JPG,jpeg,JPEG,png,PNG,webp,WEBP,gif,GIF}")

file_paths.each do |file_path|
  basename = File.basename(file_path)
  response = post_file_to_loforo(file_path, LOFORO_ENDPOINT, LOFORO_API_KEY)
  if(response.status.success?)
    puts "posting file #{file_path} successful :)"
    # append to uploaded collection
    uploaded << { "filename" => basename, "uploaded_at" => Time.now.utc.to_s }

    # move to uploaded dir
    dest_path = File.join(uploaded_dir, basename)
    FileUtils.move(file_path, dest_path)
  else
    puts "posting file #{file_path} failed :("
  end
end

# sync uploaded.json
uploaded_json_path = File.join(dir_path, "uploaded.json")
if(File.exist?(uploaded_json_path))
  # load up the oldies to not lose them
  old_uploads = JSON.load_file(uploaded_json_path)
  uploaded = old_uploads + uploaded
else # we will make new
end

File.open(uploaded_json_path, "w") do |f|
  f.write(JSON.dump(uploaded))
end
