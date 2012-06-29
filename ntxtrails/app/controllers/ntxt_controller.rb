class NtxtController < ApplicationController

    skip_before_filter :verify_authenticity_token, :only => [ :put ]

    def index
    end

    def list
    end

    def get
        send_data "FILE",
                  :type => 'application/octet-stream',
                  :filename => 'note'
    end

    def put
        head :no_content, :content_length => '0'
    end
end
