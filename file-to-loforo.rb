LOFORO_ENDPOINT = "https://loforo.com/api/post/create"

require "./loforo_lib"

file_path = ARGV[0]

if(file_path.nil? || !File.exist?(file_path) || !File.file?(file_path))
  abort "need valid path to media file"
else
  puts "#{file_path} ..."
end

res = post_file_to_loforo(file_path, LOFORO_ENDPOINT, LOFORO_API_KEY)
puts res.inspect
