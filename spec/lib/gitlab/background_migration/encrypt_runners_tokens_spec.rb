require 'spec_helper'

describe Gitlab::BackgroundMigration::EncryptRunnersTokens, :migration, schema: 20181121111200 do
  let(:settings) { table(:application_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:runners) { table(:ci_runners) }

  context 'when migrating application settings' do
    before do
      settings.create!(id: 1, runners_registration_token: 'plain-text-token1')
    end

    it 'migrates runners registration tokens' do
      migrate!(:settings, :runners_registration_token, 1, 1)

      encrypted_token = settings.first.runners_registration_token_encrypted
      decrypted_token = ::Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)

      expect(decrypted_token).to eq 'plain-text-token1'
      expect(settings.first.runners_registration_token).to be_nil
    end
  end

  context 'when migrating namespaces' do
    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token1')
      namespaces.create!(id: 12, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token2')
      namespaces.create!(id: 22, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token3')
    end

    it 'migrates runners registration tokens' do
      migrate!(:namespace, :runners_token, 11, 22)

      expect(namespaces.all.reload).to all(
        have_attributes(runners_token: nil, runners_token_encrypted: be_a(String))
      )
    end
  end

  context 'when migrating projects' do
    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org')
      projects.create!(id: 111, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token1')
      projects.create!(id: 114, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token2')
      projects.create!(id: 116, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token3')
    end

    it 'migrates runners registration tokens' do
      migrate!(:project, :runners_token, 111, 116)

      expect(projects.all.reload).to all(
        have_attributes(runners_token: nil, runners_token_encrypted: be_a(String))
      )
    end
  end

  context 'when migrating runners' do
    before do
      runners.create!(id: 201, runner_type: 1, token: 'plain-text-token1')
      runners.create!(id: 202, runner_type: 1, token: 'plain-text-token2')
      runners.create!(id: 203, runner_type: 1, token: 'plain-text-token3')
    end

    it 'migrates runners communication tokens' do
      migrate!(:runner, :token, 201, 203)

      expect(runners.all.reload).to all(
        have_attributes(token: nil, token_encrypted: be_a(String))
      )
    end
  end

  def migrate!(model, attribute, from, to)
    model = "::Gitlab::BackgroundMigration::Models::EncryptColumns::#{model.to_s.capitalize}"

    subject.perform(model, [attribute], from, to)
  end
end
