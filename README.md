# lambda_vault_auth

`lambda_vault_auth` provides a streamlined way to authenticate your Ruby AWS Lambda
function to [Hashicorp Vault](https://www.vaultproject.io).

## Usage Example

```ruby
    require 'lambda_vault_auth'

    def handler(context:, event:)
      vault = LambdaVaultAuth.vault()

      secrets := vault.logical.read('secrets/are/found/here')
      puts "Your password is: '#{secrets.data[:password]}'"
    end
```


## Setup

First, you'll need Vault up and running somewhere network-accessible to your
Lambda function. That's out of scope for this README, but please see the
[Vault documentation](https://www.vaultproject.io/docs/install/index.html)
for more.

Then you'll need to set up an AWS authentication provider. You may already have
one configured. If so, you can use that one or you can set up a new one just for
this purpose. You don't need to worry about backend credentials for this
authentication method. It works without any AWS credentials needing to be loaded
into Vault. Or if you do have credentials loaded they don't need to have access
to the AWS account your Lambda is running in.

To establish a new AWS authentication provider, run:

    $ vault auth enable -path lambda -description "IAM auth for Lambdas" aws
    Success! Enabled aws auth method at: lambda/

You will also need to set the `iam_server_id_header_value` if you wish to use
the extra layer of security (as described below):

    $ vault write auth/lambda/config/client \
          iam_server_id_header_value=vault.example.com

Next, you'll need to establish whatever Vault policies your Lambda will need.
See the [Vault Policies](https://www.vaultproject.io/docs/concepts/policies.html)
documentation for details.

Now you'll need to know the ARN of your Lambda execution role. You can create it
with the Lambda web console or by hand. Either way it should look something like:

    arn:aws:iam::987654321098:role/service-role/MyLambdaRole

*IMPORTANT*: You must remove any non-essential path from the role ARN unless you
have configured your AWS auth provider with IAM permissions to look up roles. In
this example, `service-role/` is the path segment. So the principal ARN you will
be specifying to Vault in the next step will be:

    arn:aws:iam::987654321098:role/MyLambdaRole

Now it's time to create the Vault authentication role. It can be named anything
you wish. In this case, we'll call it `my-vault-role` and make it periodic since
`lambda_vault_auth` will handle renewal automatically:

    $ vault write auth/lambda/role/my-vault-role \
          auth_type=iam \
          period=14400 \
          policies=list-of,vault-policies,separated-by-commas \
          resolve_aws_unique_ids=false \
          bound_iam_principal_arn=arn:aws:iam::987654321098:role/MyLambdaRole

Now you are ready to configure your Lambda.

## Configuration

All configuration is done with environment variables:

* `VAULT_ADDR` (Required) The URL of the Vault instance, eg `https://myvault.example.com`.
* `VAULT_AUTH_PROVIDER` (Required) The relative path of the AWS authentication provider, eg `lambda` for `auth/lambda` in the example above.
* `VAULT_AUTH_ROLE` (Required) The name of the Vault role to authenticate to, eg `my-vault-role` in the example above.
* `VAULT_AUTH_HEADER` (Optional, but recommended) The value of the `X-Vault-AWS-IAM-Server-ID` HTTP header to be included in the signed STS request this code uses to authenticate. This value is often set to the URL or DNS name of the Vault server to prevent potential replay attacks.

That should be all that is required to get up and running.

## Contributing to lambda_vault_auth

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


## License

This software is public domain. No rights are reserved. See LICENSE for more
information.
