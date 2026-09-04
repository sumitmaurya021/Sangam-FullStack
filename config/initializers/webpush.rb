# frozen_string_literal: true

require 'webpush'
require 'openssl'
require 'base64'

# Compatibility patch for Webpush with OpenSSL 3.0+
module Webpush
  class VapidKey
    def initialize(pkey = nil)
      @curve = pkey
      @curve = OpenSSL::PKey::EC.generate('prime256v1') if @curve.nil?
    end

    def self.from_keys(public_key, private_key)
      key = new
      key.set_keys!(public_key, private_key)
      key
    end

    def public_key=(key)
      set_keys!(key, nil)
    end

    def private_key=(key)
      set_keys!(nil, key)
    end

    def set_keys!(public_key = nil, private_key = nil)
      pub = if public_key.nil?
              curve.public_key
            else
              OpenSSL::PKey::EC::Point.new(group, to_big_num(public_key))
            end

      priv = if private_key.nil?
               curve.private_key
             else
               to_big_num(private_key)
             end

      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer.new(1),
        OpenSSL::ASN1::OctetString(priv.to_s(2)),
        OpenSSL::ASN1::ObjectId('prime256v1', 0, :EXPLICIT),
        OpenSSL::ASN1::BitString(pub.to_octet_string(:uncompressed), 1, :EXPLICIT)
      ])

      @curve = OpenSSL::PKey::EC.new(asn1.to_der)
    end
  end
end

# Default persistent fallback keys for Development / Test environments
# In production, specify ENV['VAPID_PUBLIC_KEY'], ENV['VAPID_PRIVATE_KEY'], and ENV['VAPID_SUBJECT']
DEFAULT_VAPID_PUBLIC_KEY = 'BGnS35p3CzAV2V6LKqleyXZprlQJ8I7MOJG5OENcjN3LY75gdY6VgbXGtzlU69ayroZRNNeaShtf2g7aCJ-Pi4o='
DEFAULT_VAPID_PRIVATE_KEY = 'Ud3qetGyS9nkYP_Q6x8MmPYdyxYXtlW2OGr2dCqBj0o='
DEFAULT_VAPID_SUBJECT = 'mailto:notifications@sangam.social'

Rails.application.configure do
  config.vapid_public_key = ENV['VAPID_PUBLIC_KEY'].presence || DEFAULT_VAPID_PUBLIC_KEY
  config.vapid_private_key = ENV['VAPID_PRIVATE_KEY'].presence || DEFAULT_VAPID_PRIVATE_KEY
  config.vapid_subject = ENV['VAPID_SUBJECT'].presence || DEFAULT_VAPID_SUBJECT
end
