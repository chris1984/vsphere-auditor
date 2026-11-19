class CollectEventsJob < ApplicationJob
  queue_as :default

  def perform
    VcenterEventCollector.collect_all
  end
end
