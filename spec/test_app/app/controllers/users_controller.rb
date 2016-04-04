class UsersController < ApplicationController
  def index
    @users = User.all
    params['sort'] ||= 'id'
    params['dir'] ||= 'desc'

    @table  = CleverTable::CleverTable.new(
        @users,
        params,
        '#'               => :id,
        'Name'            => :name,
        'Status'          => :birthdate,

        :per_page         => 3,
        :unique           => :id,
        :controller       => self
    )
  end
end