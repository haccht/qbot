
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "qbot/version"

Gem::Specification.new do |spec|
  spec.name          = "qbot"
  spec.version       = Qbot::VERSION
  spec.authors       = ["haccht"]
  spec.email         = ["haccht@users.noreply.github.com"]

  spec.summary       = %q{Tiny chatbot flamework.}
  spec.description   = %q{Tiny chatbot flamework.}
  spec.homepage      = "https://github.com/haccht/qbot"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"

  spec.add_dependency "rake", "~> 10.0"
  spec.add_dependency "dotenv", "~> 2.5"
  spec.add_dependency "timers", "~> 4.1"
  spec.add_dependency "parse-cron", "~> 0.1"
  spec.add_dependency "leveldb", "~> 0.1"
  spec.add_dependency "faraday", "~> 0.14"
  spec.add_dependency "faraday_middleware", "~> 0.12"
  spec.add_dependency "httpclient", ">= 2.6"
  spec.add_dependency "faye-websocket", "~> 0.10"
end
