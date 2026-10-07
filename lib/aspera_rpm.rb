# frozen_string_literal: true

# Helpers to extract metadata from the Aspera HSTS RPM
module AsperaRpm
  RPM_GLOB = 'private/*.rpm'
  # RPM architecture => Docker platform
  DOCKER_PLATFORMS = { 'aarch64' => 'linux/arm64', 'x86_64' => 'linux/amd64' }.freeze

  def self.path
    files = Dir.glob(RPM_GLOB)
    raise "No RPM found matching #{RPM_GLOB}" if files.empty?
    raise "Multiple RPMs found: #{files.join(', ')}" if files.size > 1
    files.first
  end

  def self.info
    @info ||= begin
      raw = `rpm -qip #{path} 2>/dev/null`
      {
        name:    raw[/^Name\s*:\s*(.+)/, 1]&.strip,
        version: raw[/^Version\s*:\s*(.+)/, 1]&.strip,
        release: raw[/^Release\s*:\s*(.+)/, 1]&.strip,
        arch:    raw[/^Architecture\s*:\s*(.+)/, 1]&.strip,
      }
    end
  end

  def self.version  = info[:version]
  def self.arch     = info[:arch]
  def self.filename = File.basename(path)
  def self.docker_platform = DOCKER_PLATFORMS.fetch(arch) { raise "Unsupported RPM architecture: #{arch}" }

  # Full version tag used for Docker images
  def self.image_tag = "#{version}"
end
