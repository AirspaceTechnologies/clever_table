require 'rails_helper'
require 'user'

describe UsersController do
  before(:all) do
    users = FactoryGirl.create_list(:user, 7)
  end

  it 'has the test data' do
    # (0..6).each do |i|
    #   let ('user' + i.to_s).to_sym { FactoryGirl.create :user, inst: i}
    # end
    expect(User.count).to equal(7)
  end

  it 'can show users' do
    get :index
  end
end