class RootController < ApplicationController
  before_filter :authenticate!, :except => :index

  def index
  end
end
