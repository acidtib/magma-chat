# == Schema Information
#
# Table name: users
#
#  id               :uuid             not null, primary key
#  name             :string           default(""), not null
#  email            :string           not null
#  image_url        :string
#  oauth_uid        :string           not null
#  oauth_provider   :string           not null
#  oauth_token      :string
#  oauth_expires_at :datetime
#  chats_count      :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin            :boolean          default(FALSE), not null
#
class User < ApplicationRecord
  has_many :chats, dependent: :destroy

  def tag_cloud(limit: 500)
    tag_counts = Hash.new(0)
    chats.select(:analysis).map(&:tags).flatten.each do |tag|
      tag_counts[tag] += 1
    end
    tag_counts.sort_by {|k, v| v}.reverse.take(limit).to_h
  end


  def self.from_omniauth(auth)
    auth.deep_symbolize_keys!
    where(oauth_provider: auth[:provider], oauth_uid: auth[:uid]).first_or_create do |user|
      user.name = auth[:info][:name]
      user.email = auth[:info][:email]
      user.image_url = auth[:info][:image]
      user.oauth_token = auth[:credentials][:token]
      user.oauth_expires_at = Time.at(auth[:credentials][:expires_at])
    end
  end

  def self.default
    where(name: "Default User").first_or_create do |user|
      user.email = "info@magmalabs.io"
      user.oauth_provider = "default"
      user.oauth_uid = "default"
    end
  end
end
