# frozen_string_literal: true

require_relative 'lib/aspera_rpm.rb'

REGISTRY = ENV.fetch('REGISTRY', 'localhost')
TAG      = ENV.fetch('TAG', AsperaRpm.image_tag)

def image_name
  "#{REGISTRY}/aspera-hsts:#{TAG}"
end

def docker_build
  sh "docker build " \
     "--platform #{AsperaRpm.docker_platform} " \
     "--build-arg RPM_FILE=#{AsperaRpm.path} " \
     "-t #{image_name} " \
     "-f images/aspera-hsts/Dockerfile ."
end

# ── Build ─────────────────────────────────────────────────────────────────────
desc 'Build aspera-hsts image'
task :build do
  docker_build
end

# ── Push ─────────────────────────────────────────────────────────────────────
desc 'Push aspera-hsts image to registry'
task :push do
  sh "docker push #{image_name}"
end

# ── Compose tasks ─────────────────────────────────────────────────────────────
namespace :compose do
  desc 'Start all containers (docker compose up -d)'
  task :up do
    sh 'docker compose up -d'
  end

  desc 'Stop all containers'
  task :down do
    sh 'docker compose down'
  end

  desc 'Tail logs from all containers'
  task :logs do
    sh 'docker compose logs -f'
  end
end

# ── Documentation ─────────────────────────────────────────────────────────────
# Value of an environment variable required for the documentation
def required_env(name)
  ENV.fetch(name) { raise "The environment variable #{name} is not set. Please set it and try again." }
end

file 'README.pdf' => 'README.md' do |t|
  # Folder of gfm2pdf-toolchain 1.x, and look of the PDF (theme folder, used by the toolchain)
  pandoc = File.join(required_env('GFM2PDF_HOME'), 'lib', 'pandoc.rb')
  required_env('GFM2PDF_THEME')
  sh 'ruby', pandoc, 'version', '>= 1.0.0.pre, < 2'
  sh 'ruby', pandoc, 'pdf', t.source, t.name
end

desc 'Generate README.pdf from README.md (env vars: GFM2PDF_HOME, GFM2PDF_THEME)'
task pdf: 'README.pdf'

# ── Default ───────────────────────────────────────────────────────────────────
desc 'Build aspera-hsts image (default)'
task default: :build
