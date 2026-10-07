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
# Folder of gfm2pdf-toolchain: next to this repository by default
GFM2PDF_DIR = ENV.fetch('GFM2PDF_DIR', File.expand_path('../gfm2pdf-toolchain', __dir__))

file 'README.pdf' => 'README.md' do |t|
  sh 'ruby', File.join(GFM2PDF_DIR, 'lib', 'pandoc.rb'), 'pdf', t.source, t.name
end

desc 'Generate README.pdf from README.md (gfm2pdf-toolchain in GFM2PDF_DIR)'
task pdf: 'README.pdf'

# ── Default ───────────────────────────────────────────────────────────────────
desc 'Build aspera-hsts image (default)'
task default: :build
