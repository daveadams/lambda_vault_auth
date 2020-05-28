require_relative '../lib/lambdavault'

describe LambdaVaultAuth do
  it 'responds to Vault' do
    expect(described_class.respond_to?(:Vault)).to be true
  end
end

describe LambdaVaultAuth::Vaulter do
  let(:vault_env) do
    {
      'VAULT_ADDR' => 'vault_addr',
      'VAULT_AUTH_PROVIDER' => 'auth_provider',
      'VAULT_AUTH_ROLE' => 'auth_role'
    }
  end
  let(:sts_client) { Aws::STS::Client.new stub_responses: true }
  subject(:vaulter) { LambdaVaultAuth::Vaulter.new(sts_client, vault_env) }

  it 'loads vault configuration from the environment' do
    expect(Vault::Client).to receive(:new).with(address: vault_env['VAULT_ADDR'])

    %i[auth_provider auth_role].each do |k|
      expect(vaulter.send(k)).to eq k.to_s
    end
  end

  describe 'with a stubbed vault client' do
    let(:vault_stub) { double('vault_client') }
    let(:logical_stub) { double('logical') }
    let(:secret_stub) { double('secret') }
    let(:secret_warnings) { {} }
    let(:auth_client_token) { 'client_token' }
    let(:secret_lease_duration) { 500 }

    let(:auth_stub) { double('auth') }
    let(:auth_is_renewable) { true }

    before do
      allow(Vault::Client).to receive(:new).with(address: vault_env['VAULT_ADDR']).and_return(vault_stub)
      allow(vault_stub).to receive(:logical).and_return(logical_stub)
      allow(secret_stub).to receive(:warnings).and_return(secret_warnings)
      allow(secret_stub).to receive(:auth).and_return(auth_stub)
      allow(secret_stub).to receive(:lease_duration).and_return(secret_lease_duration)

      allow(auth_stub).to receive(:renewable).and_return(auth_is_renewable)
      allow(auth_stub).to receive(:client_token).and_return(auth_client_token)
    end

    it 'gets called w/ sts params' do
      req = sts_client.get_caller_identity.context.http_request

      expected_data = hash_including(
        :iam_request_body,
        :iam_request_headers,
        :iam_request_url,
        iam_http_request_method: req.http_method,
        role: 'auth_role'
      )
      expect(logical_stub).to receive(:write).with('auth/auth_provider/login',
                                                   expected_data).and_return(secret_stub)
      expect(vault_stub).to receive(:token=).with(auth_client_token)
      vaulter.authenticate!
    end

    context '#expired?' do
      subject { vaulter.expired? }
      let(:expiration_val) { Time.now - 10 }
      before do
        allow(vaulter).to receive(:expiration).and_return(expiration_val)
      end
      context 'if expiration is nil' do
        let(:expiration_val) { nil }
        it { should be true }
      end

      context 'if <10 seconds have passed' do
        let(:expiration_val) { Time.now + 4 }
        it { should be false }
      end

      context 'if >=10 seconds have passed' do
        let(:expiration_val) { Time.now + 11 }
        it { should be true }
      end
    end

    context '#should_renew?' do
      subject { vaulter.should_renew? }
      let(:expiration_val) { Time.now - 10 }
      before do
        allow(vaulter).to receive(:expiration).and_return(expiration_val)
      end
      context 'if expiration is nil' do
        let(:expiration_val) { nil }
        it { should be true }
      end

      context 'if <300 seconds have passed' do
        let(:expiration_val) { Time.now + 4 }
        it { should be true }
      end

      context 'if >=300 seconds have passed' do
        let(:expiration_val) { Time.now + 301 }
        it { should be false }
      end
    end
  end
end
