require 'rails_helper'

RSpec.describe Chat do
  before do
    allow(Gpt).to receive(:chat)
  end

  describe '#directive' do
    let(:chat) { build(:chat) }

    it 'delegates directive to bot' do
      expect(chat.directive).to eq chat.bot.directive
    end
  end

  describe '#bot' do
    let(:chat) { build(:chat, bot: nil) }
    let(:bot) { Bot.default }

    it 'returns default bot id' do
      expect(chat.bot).to eq bot
    end

    context 'when bot is present' do
      let(:chat) { create(:chat) }
      let(:bot) { chat.bot }

      it 'returns assigned bot' do
        expect(chat.bot_id).to eq bot.id
      end
    end
  end

  describe '#bot_id' do
    let(:chat) { build(:chat, bot: nil) }
    let(:bot) { Bot.default }

    it 'returns default bot id' do
      expect(chat.bot_id).to eq bot.id
    end

    context 'when bot is present' do
      let(:chat) { create(:chat) }
      let(:bot) { chat.bot }

      it 'returns assigned bot id' do
        expect(chat.bot_id).to eq bot.id
      end
    end
  end

  describe '#prompt!' do
    let(:chat) { create(:chat) }

    let(:sender) { chat.user }
    let(:message) { 'Message!' }
    let(:visible) { true }

    it 'creates a message', :aggregate_failures do
      expect { chat.prompt!(message: message, visible: visible, sender: sender) }
        .to change(chat.messages, :count).by(1)

      last_message = chat.messages.last
      expect(last_message.sender).to eq sender
      expect(last_message.role).to eq 'user'
      expect(last_message.content).to eq message
      expect(last_message.visible).to eq visible
    end
  end

  describe '#redo!' do
    let(:chat) { create(:chat) }
    let(:sender) { chat.user }
    let(:message) { 'Hello!' }

    it 'deletes last messages and calls prompt! with message', :aggregate_failures do
      expect(chat).to receive(:prompt!)
        .with(message: message, sender: sender)

      expect(chat.messages.count).to eq 2

      chat.redo!(sender, message)

      expect(chat.messages.count).to eq 0
    end

    context 'when message is not present' do
      let(:message) { nil }
      let(:last_message_content) { chat.messages.by_user(sender).last.content }

      it 'deletes last messages and calls prompt! with last prompt', :aggregate_failures do
        expect(chat).to receive(:prompt!)
          .with(message: last_message_content, sender: sender)

        expect(chat.messages.count).to eq 2

        chat.redo!(sender, message)

        expect(chat.messages.count).to eq 0
      end
    end
  end

  describe '#reindex' do
    xit 'reindexes' do
    end
  end

  describe 'language' do
    let(:chat) { build(:chat, analysis: { language: language }) }
    let(:language) { 'english' }

    it 'returns language value from analysis' do
      expect(chat.language).to eq language
    end
  end

  describe 'sentiment' do
    let(:chat) { build(:chat, analysis: { sentiment: sentiment }) }
    let(:sentiment) { 'sentiment' }

    it 'returns sentiment value from analysis' do
      expect(chat.sentiment).to eq sentiment
    end
  end

  describe 'summary' do
    let(:chat) { build(:chat, analysis: { summary: summary }) }
    let(:summary) { 'summary' }

    it 'returns summary value from analysis' do
      expect(chat.summary).to eq summary
    end
  end

  describe '#messages_for_gpt' do
    subject(:messages_for_gpt) { chat.messages_for_gpt }

    let(:chat) { create(:chat, message_count: 1) }
    let(:message) { chat.messages.first }

    before do
      allow_any_instance_of(Chat).to receive(:add_context_messages)
    end

    it 'returns an array of hashes with role and content', :aggregate_failures do
      expect(messages_for_gpt.count).to eq 1

      first_message = messages_for_gpt.first
      expect(first_message[:role]).to eq message.role
      expect(first_message[:content]).to eq message.content
    end
  end

  describe '#analysis_next' do
    let(:chat) { build(:chat, analysis: { next: analysis_next }) }
    let(:analysis_next) { 'analysis_next' }

    it 'returns next value analysis' do
      expect(chat.analysis_next).to eq analysis_next
    end

    context 'when key is missing from analysis' do
      let(:analysis_next) { nil }

      it 'returns an empty array' do
        expect(chat.analysis_next).to eq []
      end
    end
  end

  describe '#tags' do
    let(:chat) { build(:chat, analysis: { tags: tags }) }
    let(:tags) { ['tag1', 'tag2'] }

    it 'returns tags value from analysis' do
      expect(chat.tags).to eq tags
    end

    context 'when key is missing from analysis' do
      let(:tags) { nil }

      it 'returns an empty array' do
        expect(chat.tags).to eq []
      end
    end
  end

  describe '#add_context_messages' do
    let(:chat) { create(:chat) }

    let(:context_user_prompt) do
      Prompts.get('chats.context_user', {
        bot_name: chat.bot.name,
        user_name: chat.user.name,
        date: Date.today.strftime("%B %d, %Y"),
        time: Time.now.strftime("%I:%M %p")
      })
    end

    before do
      expect_any_instance_of(Chat).to receive(:add_context_messages).and_call_original
    end

    it 'creates context messages', :aggregate_failures do
      expect(chat.messages.count).to eq 2

      user_message, bot_message = chat.messages
      expect(user_message.sender).to eq chat.user
      expect(user_message.role).to eq 'user'
      expect(user_message.content).to eq context_user_prompt
      expect(user_message.skip_broadcast).to eq false
      expect(user_message.visible).to eq false

      expect(bot_message.sender).to eq chat.bot
      expect(bot_message.role).to eq 'assistant'
      expect(bot_message.content).to eq Prompts.get('chats.context_reply', lang: 'English')
      expect(bot_message.skip_broadcast).to eq false
      expect(bot_message.visible).to eq false
    end
  end

  describe '#set_title' do
    let(:chat) { create(:chat, title: nil, first_message: message) }
    let(:message) { 'Hello World!' }

    it 'sets first_message as the title' do
      expect(chat.title).to eq message
    end

    context 'when first_message is not present' do
      let(:message) { nil }

      it 'sets a default title' do
        expect(chat.title).to eq "Conversation with #{chat.bot.name}"
      end
    end
  end
end