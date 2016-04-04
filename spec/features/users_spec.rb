require 'rails_helper'
require 'user'

describe UsersController do
  before(:all) do
    users = FactoryGirl.create_list(:user, 7)
  end

  it 'has the test data' do
    expect(User.count).to equal(7)
  end

  it 'can show users', js: true do
    visit users_path
    expect(page).to have_content('bob')
  end
end