require 'securerandom'

class BroadcastsController < ApplicationController
  def new
    if request.post?
      random_channel_id = SecureRandom.urlsafe_base64
      redirect_to  :action => "tx", :key => random_channel_id
    end
  end

  def rx

  end

  def tx

  end
end
