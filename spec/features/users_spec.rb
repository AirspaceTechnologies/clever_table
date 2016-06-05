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
    expect(page).to have_css('td')
  end

  it 'can sort', js: true do
    visit users_path
    find('[data-col=birthdate]').click
    find('[data-col=birthdate]').click
    expect(all('td')[1]).to have_content('steve')
    expect(all('td')[4]).to have_content('jane')
  end
end