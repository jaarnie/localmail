module Localmail
  # The inbox: lists, shows and deletes captured messages.
  class MessagesController < ApplicationController
    before_action :set_messages, only: :index
    before_action :set_message, only: :show

    def index; end

    def show; end

    def destroy
      Store.delete(params[:id])

      redirect_to root_path
    end

    def destroy_all
      Store.clear

      redirect_to root_path
    end

    private

    def set_messages
      @messages = Store.all
    end

    def set_message
      @message = Store.find(params[:id])

      redirect_to root_path if @message.nil?
    end
  end
end
