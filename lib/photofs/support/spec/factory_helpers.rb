module PhotoFS
  module Support
    module Spec
      module FactoryHelpers
        def create_images(paths)
          paths.map { |path| create_image path }
        end

        # legacy; can be refactored out
        def create_image(path)
          create(:image, path: path)
        end
      end
    end
  end
end
