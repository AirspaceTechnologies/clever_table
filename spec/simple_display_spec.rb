require 'rails_helper'
require 'user'

describe 'Users' do
  it 'has the fixtures' do
    # (0..6).each do |i|
    #   let ('user' + i.to_s).to_sym { FactoryGirl.create :user, inst: i}
    # end
    users = FactoryGirl.create_list(:user, 7)
    expect(User.count).to equal(7)
  end
end