#!/bin/env ruby
require_relative '../lib/lambdavault'

v = LambdaVaultAuth.Vault()

p v
secrets = v.logical.read('secrets/are/found/here')
puts 'Your password is: ' + secrets.data[:password]
