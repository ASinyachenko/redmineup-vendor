module Redmineup
  module Patches
    module AutoCompletesControllerPatch
      DEFAULT_TAGS_LIMIT = 10

      def taggable_tags
        limit = params.delete(:limit) || DEFAULT_TAGS_LIMIT
        klass = Object.const_get(params[:taggable_type].camelcase) if params[:taggable_type].present?

        tags = klass && klass.available_tags(params.merge(limit: limit, name_like: params[:q])) || Redmineup::ActsAsTaggable::Tag.limit(limit)
        render json: tags.map { |tag| { id: tag.name, text: tag.name } }
      end
    end
  end
end

AutoCompletesController.prepend(Redmineup::Patches::AutoCompletesControllerPatch)
