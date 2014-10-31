require 'test_helper'

class ShardTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  def test_activation_should_persist_in_thread
    DataFabric.activate_shard(:city => 'austin')
    assert_equal 'austin', DataFabric.active_shard(:city)
  end
  
  def test_activation_in_one_thread_does_not_change_another
    assert_raises ArgumentError do
       DataFabric.active_shard(:city)
     end
    DataFabric.activate_shard(:city => 'austin')

    Thread.new do
      assert_raises ArgumentError do
         DataFabric.active_shard(:city)
       end
      DataFabric.activate_shard(:city => 'dallas')
      assert_equal 'dallas', DataFabric.active_shard(:city)
    end.join
  end
  
  def test_activations_can_be_nested
    DataFabric.activate_shard(:name => 'Belldandy') do
      DataFabric.activate_shard(:technique => 'Thousand Years of Pain') do
        DataFabric.activate_shard(:name => 'Lelouche') do
          DataFabric.activate_shard(:technique => 'Shadow Replication') do
            assert_equal 'Shadow Replication', DataFabric.active_shard(:technique)
            assert_equal 'Lelouche', DataFabric.active_shard(:name)
          end
          assert_equal 'Thousand Years of Pain', DataFabric.active_shard(:technique)
          assert_equal 'Lelouche', DataFabric.active_shard(:name)
        end
        assert_equal 'Thousand Years of Pain', DataFabric.active_shard(:technique)
        assert_equal 'Belldandy', DataFabric.active_shard(:name)
      end
      assert_raises ArgumentError do
        DataFabric.active_shard(:technique)
      end
      assert_equal 'Belldandy', DataFabric.active_shard(:name)
    end
    assert_raises ArgumentError do
      DataFabric.active_shard(:technique)
    end
    assert_raises ArgumentError do
      DataFabric.active_shard(:name)
    end
  end
  
  def test_activate_shard_returns_result_of_block
    result = DataFabric.activate_shard(:gundam => 'Exia') do
      1234
    end
    assert_equal 1234, result
  end
end
