Gem::Specification.new do |spec|
  spec.name = 'lambda_vault_auth'.freeze
  spec.version = File.read('VERSION').chomp

  spec.require_paths = ['lib'.freeze]
  spec.authors = ['Ryan Taylor'.freeze]
  spec.date = '2020-05-13'
  spec.description = 'A library for authenticating a lambda function against Hashicorp Vault via AWS as an authentication provider.'.freeze
  spec.email = 'rtaylor@instructure.com'.freeze
  spec.files = [
    'Gemfile',
    'LICENSE',
    'README.md',
    'Rakefile',
    'VERSION',
    'lib/lambda_vault_auth.rb'
  ]
  spec.homepage = 'http://github.com/instructure/lambda_vault_auth'.freeze
  spec.licenses = ['CC0-1.0'.freeze]
  spec.summary = 'Simplify authentication between an AWS lambda function and Hashicorp Vault via the AWS authentication provider.'.freeze

  spec.add_runtime_dependency('aws-sdk-core'.freeze, ['>= 3.0'])
  spec.add_runtime_dependency('vault'.freeze, ['~> 0.13'])

  spec.add_development_dependency('bundler'.freeze, ['~> 2.0'])
  spec.add_development_dependency('rspec'.freeze, ['~> 3.5'])
end
