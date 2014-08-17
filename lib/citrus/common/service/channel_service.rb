# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 29 July 2014

require 'citrus/common/remote/frontend/channel_remote'
require 'citrus/util/countdown_latch'

module Citrus
  # Common
  #
  #
  module Common
    # Service
    #
    #
    module Service
      # ChannelService
      #
      #
      class ChannelService
        # Util
        #
        #
        module Util
          private

          # Add uid and server id into group
          #
          # @param [String] uid
          # @param [String] sid
          # @param [Hash]   groups
          #
          # @private
          def add uid, sid, groups
            unless sid
              return false
            end

            group = groups[sid]
            group = []; groups[sid] = group unless group

            group << uid; true
          end

          # Delete element from array
          #
          # @param [String] uid
          # @param [String] sid
          # @param [Array]  group
          #
          # @private
          def delete_from uid, sid, group
            return true unless group

            group.each { |e|
              group.delete e; return true if e == uid
            }
            return false
          end

          # Push message by group
          #
          # @param [Object] service
          # @param [String] route
          # @param [Hash]   msg
          # @param [Hash]   groups
          # @param [Hash]   args
          #
          # @private
          def send_message_by_group service, route, msg, groups, args, &block
            app = service.app
            namespace = 'sys'
            service = 'channelRemote'
            method = 'pushMessage'
            count = groups.length
            success_flag = false
            fail_ids = []

            block_given? and yield if count == 0

            latch = Utils::CountDownLatch.new(count) {
              unless success_flag
                block_given? and yield Exception.new 'all uids push message fail'
                return
              end
              block_given? and yield nil, fail_ids
            }

            rpc_cb = Proc.new { |server_id|
              Proc.new { |err, fails|
                if err
                  latch.done
                  return
                end
                fail_ids += fails if fails
                success_flag = true
                latch.done
              }
            }

            args = { :type => 'push', :user_args => args || {} }

            send_message = Proc.new { |sid|
              if sid == app.server_id
                service.channelRemote.send method, route, msg, groups[sid], args, &rpc_cb.call
              else
                app.rpc_invoke(sid, {
                  :namespace => namespace,
                  :service => service,
                  :method => method,
                  :args => [route, msg, groups[sid], args]
                }, &rpc_cb.call(sid))
              end
            }

            groups.each_with_index { |group, sid|
              if group && group.length > 0
                send_message sid
              else
                EM.next_tick { rpc_cb.call.call }
              end
            }
          end

          # Restore channel
          #
          # @param [Object] service
          #
          # @private
          def restore_channel service, &block
            if service.store
              block_given? and yield
              return
            end

            load_all_from_store(service, gen_key(service)) { |err, list|
              if err
                block_given? and yield err
                return
              end

              unless (list.instance_of? Array) && list.lenth > 0
                block_given? and yield
                return
              end

              load_p = Proc.new { |key|
                load_all_from_store(service, key) { |err, items|
                  items.each { |item|
                    sid, uid = item.split ':'
                    channel = service.channels[name]
                    if add uid, sid, channel.groups
                      channel.records[uid] = { :sid => sid, :uid => uid }
                    end
                  }
                }
              }

              list.each_index { |index|
                name = list[index][gen_key(service).length+1..-1]
                service.channels[name] = Channel.new name, service
                load_p.call list[index]
              }
              block_given? and yield
            }
          end

          # Add to store
          #
          # @param [Object] service
          # @param [String] key
          # @param [Hash]   value
          #
          # @private
          def add_to_store service, key, value
            if service.store
              service.store.add(key, value) { |err|
                if err
                end
              }
            end
          end

          # Remove from store
          #
          # @param [Object] service
          # @param [String] key
          # @param [Hash]   value
          #
          # @private
          def remove_from_store service, key, value
            if service.store
              service.store.remove(key, value) { |err|
                if err
                end
              }
            end
          end

          # Load all from store
          #
          # @param [Object] service
          # @param [String] key
          #
          # @private
          def load_all_from_store service, key, &block
            if service.store
              service.store.load(key) { |err, list|
                if err
                  block_given? and yield err
                else
                  block_given? and yield nil, list
                end
              }
            end
          end

          # Remove all from store
          #
          # @param [Object] service
          # @param [String] key
          #
          # @private
          def remove_all_from_store service, key
            if service.store
              service.store.remove_all(key) { |err|
                if err
                end
              }
            end
          end

          # Generate key
          #
          # @param [Object] service
          # @param [String] name
          #
          # @private
          def gen_key service, name=''
            unless name.empty?
              service.prefix + ':' + service.app.server_id + ':' + name
            else
              service.prefix + ':' + service.app.server_id
            end
          end

          # Generate value
          #
          # @param [String] sid
          # @param [String] uid
          #
          # @private
          def gen_value sid, uid
            sid + ':' + uid
          end
        end

        include Util

        attr_reader :app, :channels, :prefix, :store, :channel_remote

        # Initialize the service
        #
        # @param [Object] app
        # @param [Hash]   args
        def initialize app, args={}
          @app = app
          @channels = {}
          @prefix = args[:prefix]
          @store = args[:store]
          @broadcast_filter = args[:broadcast_filter]
          @channel_remote = Remote::Frontend::ChannelRemote.new app
        end

        # Start the service
        def start &block
          restore_channel self, &block
        end

        # Create channel with name
        #
        # @param [String] name
        def create_channel name
          return @channels[name] if @channels[name]

          c = Channel.new name
          add_to_store self, gen_key(self), gen_key(self, name)
          @channels[name] = c
          c
        end

        # Get channel by name
        #
        # @param [String]  name
        # @param [Boolean] create
        def get_channel name, create=false
          channel = @channels[name]
          if !channel && create
            channel = @channels[name] = Channel.new name
            add_to_store self, gen_key(self), gen_key(self, name)
          end
          channel
        end

        # Destroy channel by name
        #
        # @param [String] name
        def destroy_channel name
          @channels.delete name
          remove_from_store self, gen_key(self), gen_key(self, name)
          remove_all_from_store self, gen_key(self, name)
        end

        # Push message by uids
        #
        # @param [String] route
        # @param [Hash]   msg
        # @param [Array]  uids
        # @param [Hash]   args
        def push_message_by_uids route, msg, uids, args, &block
          unless uids && uids.length != 0
            block_given? and yield Exception.new 'uids should not be empty'
            return
          end

          groups = {}
          uids.each { |record| add record[:uid], record[:sid], groups }

          send_message_by_group self, route, msg, groups, args, &block
        end

        # Broadcast message to all the connected clients
        #
        # @param [String] server_type
        # @param [String] route
        # @param [Hash]   message
        # @param [Hash]   args
        def broadcast server_type, route, msg, args, &block
          namespace = 'sys'
          service = 'channelRemote'
          method = 'broadcast'
          servers = @app.get_servers_by_type server_type

          unless servers && servers.length != 0
            # server list is empty
            block_given? and yield
          end

          count = servers.length
          success_flag = false

          latch = Utils::CountDownLatch.new(count) {
            unless success_flag
              block_given? and yield Exception.new 'broadcast failed'
              return
            end
            block_given? and yield nil
          }

          gen_cb = Proc.new { |server_id|
            Proc.new { |err|
              if err
                latch.done
                return
              end
              success_flag = true
              latch.done
            }
          }

          send_message = Proc.new { |server_id|
            if server_id == @app.server_id
              @channel_remote.send method, route, msg, args, &gen_cb.call
            else
              @app.rpc_invoke(server_id, {
                :namespace => namespace,
                :service => service,
                :method => method,
                :args => [route, msg, args]
              }, &gen_cb.call(server_id))
            end
          }

          args = { :type => 'broadcast', :user_args => args || {} }

          servers.each { |server|
            send_message server[:server_id]
          }
        end

        # Channel
        #
        #
        class Channel
          include Util

          attr_reader :groups, :user_amount

          # Create a new channel
          #
          # @param [String] name
          # @param [Object] service
          def initialize name, service
            @name = name
            @groups = {}
            @records = {}
            @channel_service = service
            @state = :state_inited
            @user_amount = 0
          end

          # Add user to channel
          #
          # @param [String] uid
          # @param [String] sid
          def add uid, sid
            return false unless @state == :state_inited

            res = add uid, sid, @groups
            if res
              @records[uid] = { :sid => sid, :uid => uid }
              @user_amount += 1
            end

            add_to_store @channel_service, gen_key(@channel_service, @name), gen_value(sid, uid)
            res
          end

          # Remove user from channel
          #
          # @param [String] uid
          # @param [String] sid
          def leave uid, sid
            return unless uid && sid

            @records.delete uid
            @user_amount -= 1
            @user_amout = 0 if @user_amount < 0

            remove_from_store @channel_service, gen_key(@channel_service, @name), gen_value(sid, uid)

            res = delete_from uid, sid, @groups[sid]
            if @groups[sid] && @groups[sid].length == 0
              @groups.delete sid
            end
            res
          end

          # Get channel members
          def get_members
            res = []
            @groups.each { |group| group.each { |e| res << e } }
            res
          end

          # Get member info
          #
          # @param [String] uid
          def get_member uid
            @records[uid]
          end

          # Destroy channel
          def destroy
            @state = :state_destroyed
            @channel_service.destroy_channel @name
          end

          # Push message to all the members in the channel
          #
          # @param [String] route
          # @param [Hash]   msg
          # @param [Hash]   args
          def push_message route, msg, args, &block
            unless @state == :state_inited
              block_given? and yield Exception.new 'channel is not running now'
              return
            end
            send_message_by_group @channel_service, route, msg, @groups, args, &block
          end
        end
      end
    end
  end
end
