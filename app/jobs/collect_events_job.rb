class CollectEventsJob < ApplicationJob
  queue_as :default

  def perform
    VcenterEventCollector.new.collect
  end
end
