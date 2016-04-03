class Shrine
  module Plugins
    # The moving plugin enables you to move files to specified storages. On
    # the filesystem moving is istantaneous, since the OS only changes the
    # pointer, so this plugin is useful when dealing with large files.
    #
    # This plugin is also recommended if you're doing processing, since by
    # default temporary files won't immediately get deleted (Ruby's Tempfiles
    # usually get deleted only when the process ends).
    #
    #     plugin :moving, storages: [:cache]
    #
    # The `:storages` option specifies which storages the file will be moved
    # to. The above will move raw files to cache (without this plugin it's
    # simply copied over). However, you may want to move cached files to
    # `:store` as well:
    #
    #     plugin :moving, storages: [:cache, :store]
    #
    # What exactly means "moving"? If both the file being uploaded and the
    # destination are on the filesystem, a `mv` command will be executed
    # (making the transfer instantaneous). Some other storages may implement
    # moving as well, usually only for files which are on the same storage.
    # If moving isn't implemented by the storage, the file will be simply
    # deleted after upload.
    module Moving
      def self.configure(uploader, storages:)
        uploader.opts[:move_files_to_storages] = storages
      end

      module InstanceMethods
        private

        # If the storage supports moving we use that, otherwise we do moving by
        # copying and deleting.
        def copy(io, context)
          if move?(io, context)
            if movable?(io, context)
              move(io, context)
            else
              warn "The #{storage_key.inspect} Shrine storage doesn't support moving a #{io.inspect}. It is currently still deleted, but it won't be in Shrine 2."
              super
              io.delete if io.respond_to?(:delete)
            end
          else
            super
          end
        end

        def move(io, context)
          storage.move(io, context[:location], context[:metadata])
        end

        def movable?(io, context)
          storage.respond_to?(:move) && storage.movable?(io, context[:location])
        end

        def move?(io, context)
          opts[:move_files_to_storages].include?(storage_key)
        end
      end
    end

    register_plugin(:moving, Moving)
  end
end
