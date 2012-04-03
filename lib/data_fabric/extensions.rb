require 'data_fabric/connection_proxy'

class ActiveRecord::ConnectionAdapters::ConnectionHandler
  def clear_active_connections_with_data_fabric!
    clear_active_connections_without_data_fabric!
    DataFabric::ConnectionProxy.shard_pools.each_value { |pool| pool.release_connection }
  end
  alias_method_chain :clear_active_connections!, :data_fabric
end

module DataFabric
  module Extensions
    def self.included(model)
      DataFabric.logger.info { "Loading data_fabric #{DataFabric::Version::STRING} with ActiveRecord #{ActiveRecord::VERSION::STRING}" }

      # Wire up ActiveRecord::Base
      model.extend ClassMethods
      ConnectionProxy.shard_pools = {}
    end

    # Class methods injected into ActiveRecord::Base
    module ClassMethods
      def data_fabric(options)
        DataFabric.logger.info { "Creating data_fabric proxy for class #{name}" }
        pool_proxy = PoolProxy.new(ConnectionProxy.new(self, options))
        klass_name = name
        connection_handler.instance_eval do
          if @class_to_pool
            # Rails 3.2
            @connection_pools[pool_proxy.spec]  ||= pool_proxy
            @class_to_pool[klass_name]            = connection_pools[pool_proxy.spec]
          else
            # <= Rails 3.1
            @connection_pools[klass_name] = pool_proxy
          end
        end
      end
    end
  end
end
