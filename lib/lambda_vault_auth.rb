require 'aws-sdk-core'
require 'vault'

# TODO: support the advanced vault header in the signature, since it gives us better security
# VAULT_AUTH_HEADER_NAME = "X-Vault-AWS-IAM-Server-ID".freeze

# LambdaVaultAuth
class LambdaVaultAuth
  # Internal class for Vault interactions
  class Vaulter
    attr_reader :auth_provider,
                :auth_role,
                :auth_token,
                :client,
                :expiration,
                :expiration_window,
                :renewal_window,
                :ttl

    def initialize(sts = Aws::STS::Client.new, env = ENV)
      @sts = sts
      @client = new_client_from_environment(env)

      # TODO: Make the following configurable
      # Lifecycle of each token
      @expiration_window = 10 # seconds

      # should be at least the length of the lambda runtime
      @renewal_window = 300 # seconds
    end

    def expired?
      expiration.nil? ? true : expiration > Time.now + expiration_window
    end

    def should_renew?
      expiration.nil? ? true : Time.now + renewal_window > expiration
    end

    def renewable?
      auth_token&.renewable
    end

    def renew!
      handle_token(auth_token.renew_self(ttl))
    end

    def new_client_from_environment(env)
      addr = env.fetch('VAULT_ADDR')
      # @auth_header = env.fetch('VAULT_AUTH_HEADER')
      @auth_provider = env.fetch('VAULT_AUTH_PROVIDER')
      @auth_role = env.fetch('VAULT_AUTH_ROLE')

      Vault::Client.new(
        address: addr
      )
    end

    def authenticate!
      req = @sts.get_caller_identity.context.http_request

      data = {
        'iam_http_request_method': req.http_method,
        'iam_request_body': Base64.strict_encode64(req.body.read),
        'iam_request_headers': Base64.strict_encode64(req.headers.to_h.to_json),
        'iam_request_url': Base64.strict_encode64(req.endpoint.to_s),
        'role': @auth_role
      }

      secret = client.logical.write("auth/#{@auth_provider}/login", data)

      warn secret.warnings unless secret.warnings.empty?

      handle_token(secret)

      # create the required data to renew/validate
      # populate the token on the client and hand that to the user
    end

    def handle_token(secret)
      @auth_token = secret.auth
      @ttl = secret.lease_duration
      @expiration = Time.now + ttl
      @client.token = @auth_token.client_token
    end
  end

  # LambdaVaultAuth.vault returns a wrapped vault which contains a few convenience accessors/helpers
  # to help manage the lifecycle of a vault and access the credentials
  def self.vault
    @vault ||= Vaulter.new
    @sts ||= Aws::STS::Client.new

    return @vault.client unless @vault.expired?

    if @vault.renewable? && @vault.should_renew?
      @vault.renew!
      return @vault.client
    end

    # Otherwise, authenticate
    @vault.authenticate!

    # return the vault client directly
    @vault.client
  end
end
