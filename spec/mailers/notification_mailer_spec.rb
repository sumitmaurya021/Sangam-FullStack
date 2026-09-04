require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  let(:user) { create(:user, email: 'user@example.com', name: 'John Doe') }
  let(:actor) { create(:user, name: 'Alice') }
  let(:notification) { create(:notification, recipient: user, actor: actor, notification_type: 'like') }

  describe '#notification_email' do
    let(:mail) { NotificationMailer.notification_email(notification) }

    it 'renders email headers and body' do
      expect(mail.to).to include('user@example.com')
      expect(mail.subject).to include('Sangam')
    end
  end

  describe '#welcome_email' do
    let(:mail) { NotificationMailer.welcome_email(user) }

    it 'renders welcome email subject and recipient' do
      expect(mail.to).to include('user@example.com')
      expect(mail.subject).to eq('Welcome to Sangam, John Doe!')
    end
  end
end
