# frozen_string_literal: true

require "service/shared_service_tests"

class ProActiveStorage::Service::DiskServiceTest < ActiveSupport::TestCase
  SERVICE = ProActiveStorage::Service::DiskService.new(root: File.join(Dir.tmpdir, "pro_active_storage"))

  include ProActiveStorage::Service::SharedServiceTests

  test "url generation" do
    assert_match(/^https:\/\/example.com\/rails\/pro_active_storage\/disk\/.*\/avatar\.png\?content_type=image%2Fpng&disposition=inline/,
      @service.url(@key, expires_in: 5.minutes, disposition: :inline, filename: ProActiveStorage::Filename.new("avatar.png"), content_type: "image/png"))
  end

  test "headers_for_direct_upload generation" do
    assert_equal({ "Content-Type" => "application/json" }, @service.headers_for_direct_upload(@key, content_type: "application/json"))
  end
end
