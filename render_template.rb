require 'erb'
require 'ostruct'
require 'aws-sdk'

### Environement variables example
# UPSTREAM_NAME=backend.local
# UPSTREAM_PORT=3000
# HTTP_HOSTS=login.example.com,web-front.example.com
# CERT_LOGIN_EXAMPLE_COM=s3://bucket-name/login.example.com/cert
# KEY_LOGIN_EXAMPLE_COM=s3://bucket-name/login.example.com/key
# CERT_WEB__FRONT_EXAMPLE_COM=s3://bucket-name/web-front.example.com/cert
# KEY_WEB__FRONT_EXAMPLE_COM=s3://bucket-name/web-front.example.com/key

def render_template(from, to, namespace={})
  erb = ERB.new(File.read(from))
  open(to, 'w') do |f|
    f << erb.result(OpenStruct.new(namespace).instance_eval{ binding })
  end
end

def download_s3(url, dest)
  match = url.match(/\As3:\/\/(?<bucket_name>[\w-]+)\/(?<path>.+)/)
  cli = Aws::S3::Client.new
  cli.get_object(
    bucket: match[:bucket_name],
    key: match[:path],
    response_target: dest
  )
end

render_template('/templates/nginx.conf.erb', '/etc/nginx/nginx.conf',
  upstream_name: ENV['UPSTREAM_NAME'],
  upstream_port: ENV['UPSTREAM_PORT']
)

hosts = (ENV['HTTP_HOSTS'] || "").split(',')
hosts.each do |host|
  host_key = host.gsub('.', '_').gsub('-', '__').upcase
  s3_ssl_cert_path = ENV["CERT_#{host_key}"]
  s3_ssl_key_path = ENV["KEY_#{host_key}"]

  if s3_ssl_cert_path && s3_ssl_key_path
    ssl_cert_path = "/etc/nginx/certs/#{host}.crt"
    ssl_key_path = "/etc/nginx/certs/#{host}.key"

    # download key and cert from s3
    download_s3(s3_ssl_cert_path, ssl_cert_path)
    download_s3(s3_ssl_key_path, ssl_key_path)
  end

  render_template('/templates/server.conf.erb', "/etc/nginx/conf.d/#{host}.conf",
    hostname: host,
    ssl_cert_path: ssl_cert_path,
    ssl_key_path:  ssl_key_path,
    force_ssl: ENV['FORCE_SSL'] == 'true',
    upstream_name: ENV['UPSTREAM_NAME'],
    upstream_port: ENV['UPSTREAM_PORT']
  )
end
