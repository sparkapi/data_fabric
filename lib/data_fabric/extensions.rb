require 'active_record/connection_adapters/abstract/connection_pool'
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
        @proxy = DataFabric::ConnectionProxy.new(self, options)
        
        class << self
          def connection
            @proxy || superclass.connection
          end

          def connected?
            @proxy.connected?
          end

          def remove_connection(klass=self)
            DataFabric.logger.warn { "remove_connection not implemented by data_fabric" }
          end

          def connection_pool
            raise "dynamic connection switching means you cannot get direct access to a pool"
          end
        end
      end
    end
  end
end