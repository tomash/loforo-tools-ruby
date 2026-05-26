require "http"

LOFORO_API_KEY = ENV.fetch("LOFORO_API_KEY") do
  abort "LOFORO_API_KEY environment variable is required"
end

# Input
# key (required): The API key (see API key section above)
# content (required): Text / HTML content of your post
# title (optional): Title of your post
# media (optional): Can be used to upload and attach a photo or video with your post -- must be sent as multipart/form-data data. See below for details
# status (optional): Whether the post should be Published immediately (`0` - default), Draft (`1`), or Queued (`2`) to be published on a schedule (see settings)

def post_file_to_loforo(file_path, endpoint, api_key)
  res = HTTP.post(endpoint, :form => {
    :key => api_key,
    :content => "",
    :title => "",
    :status => "0", # publish immediately
    :media   => HTTP::FormData::File.new(file_path)
  })

  res
end

