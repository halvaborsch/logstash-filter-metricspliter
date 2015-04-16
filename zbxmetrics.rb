# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Zbxmetrics < LogStash::Filters::Base

  milestone 1

  config_name "zbxmetrics"

  metric_field_name = "zabbix.item"
  metric_field_value = "zabbix.value"


  # Name of the field the metric name will be written to.
  config :metric_field_name, :validate => :string, :default => "metric"

  # Name of the field the metric value will be written to.
  config :value_field_name, :validate => :string, :default => "value"

  # Flag indicating whether the original event should be dropped or not.
  config :drop_original_event, :validate => :boolean, :default => false

  public
  def register
    # Nothing to do
  end
 
  public
  def filter(event, &block)
    return unless filter?(event)
    empty_event = event.clone
    empty_event.remove("tags")

    empty_event.to_hash.each_key do |field_name|
	if(field_name =~ /metrics/)
	    empty_event.remove(field_name)
	end
    end
    
    event.to_hash.each do |field_name,field_value|
	if(field_name =~ /metrics/)
	    zabbix_host=field_name[/[a-z0-9-]+/]
	    clone = empty_event.clone
	    clone["zabbix_host"] = zabbix_host
	    clone["zabbix_item"] = field_name
    	    clone["send_field"] = field_value.to_i*60
	    @logger.info("Cloned event", :clone => clone)
	    filter_matched(clone)
	    yield clone if block_given?
	end
    end

    if @drop_original_event
      event.cancel()
    end
  end

end
