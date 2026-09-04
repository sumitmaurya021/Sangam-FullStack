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

  module Encryption
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = 'prime256v1'
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: 'SHA256', info: info).next_bytes(32)

      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, 'encrypted payload is too big' if rs > 4096

      aes128gcmheader = "#{salt}" + [rs].pack('N*') + [serverkey16bn.bytesize].pack('C*') + serverkey16bn

      aes128gcmheader + ciphertext
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
