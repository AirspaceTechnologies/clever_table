class UsersController < ApplicationController
  def index
    @users = User.all.order 'name asc'
    params['sort'] ||= 'name'
    params['dir'] ||= 'asc'

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