begin
  require 'iconv'
rescue Object
  puts "no iconv, you might want to look into it."
end

require 'digest/sha1'
module PermalinkFu
  SEO_WORD_REGEX = /(^| )(a|able|about|above|abroad|according|accordingly|across|actually|adj|after|afterwards|again|against|ago|ahead|ain't|all|allow|allows|almost|alone|along|alongside|already|also|although|always|am|amid|amidst|among|amongst|an|and|another|any|anybody|anyhow|anyone|anything|anyway|anyways|anywhere|apart|appear|appreciate|appropriate|are|aren't|around|as|a's|aside|ask|asking|associated|at|available|away|awfully|b|back|backward|backwards|be|became|because|become|becomes|becoming|been|before|beforehand|begin|behind|being|believe|below|beside|besides|best|better|between|beyond|both|brief|but|by|c|came|can|cannot|cant|can't|caption|cause|causes|certain|certainly|changes|clearly|c'mon|co|co.|com|come|comes|concerning|consequently|consider|considering|contain|containing|contains|corresponding|could|couldn't|course|c's|currently|d|dare|daren't|definitely|described|despite|did|didn't|different|directly|do|does|doesn't|doing|done|don't|down|downwards|during|e|each|edu|eg|eight|eighty|either|else|elsewhere|end|ending|enough|entirely|especially|et|etc|even|ever|evermore|every|everybody|everyone|everything|everywhere|ex|exactly|example|except|f|fairly|far|farther|few|fewer|fifth|first|five|followed|following|follows|for|forever|former|formerly|forth|forward|found|four|from|further|furthermore|g|get|gets|getting|given|gives|go|goes|going|gone|got|gotten|greetings|h|had|hadn't|half|happens|hardly|has|hasn't|have|haven't|having|he|he'd|he'll|hello|help|hence|her|here|hereafter|hereby|herein|here's|hereupon|hers|herself|he's|hi|him|himself|his|hither|hopefully|how|howbeit|however|hundred|i|i'd|ie|if|ignored|i'll|i'm|immediate|in|inasmuch|inc|inc.|indeed|indicate|indicated|indicates|inner|inside|insofar|instead|into|inward|is|isn't|it|it'd|it'll|its|it's|itself|i've|j|just|k|keep|keeps|kept|know|known|knows|l|last|lately|later|latter|latterly|least|less|lest|let|let's|like|liked|likely|likewise|little|look|looking|looks|low|lower|ltd|m|made|mainly|make|makes|many|may|maybe|mayn't|me|mean|meantime|meanwhile|merely|might|mightn't|mine|minus|miss|more|moreover|most|mostly|mr|mrs|much|must|mustn't|my|myself|n|name|namely|nd|near|nearly|necessary|need|needn't|needs|neither|never|neverf|neverless|nevertheless|new|next|nine|ninety|no|nobody|non|none|nonetheless|noone|no-one|nor|normally|not|nothing|notwithstanding|novel|now|nowhere|o|obviously|of|off|often|oh|ok|okay|old|on|once|one|ones|one's|only|onto|opposite|or|other|others|otherwise|ought|oughtn't|our|ours|ourselves|out|outside|over|overall|own|p|particular|particularly|past|per|perhaps|placed|please|plus|possible|presumably|probably|provided|provides|q|que|quite|qv|r|rather|rd|re|really|reasonably|recent|recently|regarding|regardless|regards|relatively|respectively|right|round|s|said|same|saw|say|saying|says|second|secondly|see|seeing|seem|seemed|seeming|seems|seen|self|selves|sensible|sent|serious|seriously|seven|several|shall|shan't|she|she'd|she'll|she's|should|shouldn't|since|six|so|some|somebody|someday|somehow|someone|something|sometime|sometimes|somewhat|somewhere|soon|sorry|specified|specify|specifying|still|sub|such|sup|sure|t|take|taken|taking|tell|tends|th|than|thank|thanks|thanx|that|that'll|thats|that's|that've|the|their|theirs|them|themselves|then|thence|there|thereafter|thereby|there'd|therefore|therein|there'll|there're|theres|there's|thereupon|there've|these|they|they'd|they'll|they're|they've|thing|things|think|third|thirty|this|thorough|thoroughly|those|though|three|through|throughout|thru|thus|till|to|together|too|took|toward|towards|tried|tries|truly|try|trying|t's|twice|two|u|un|under|underneath|undoing|unfortunately|unless|unlike|unlikely|until|unto|up|upon|upwards|us|use|used|useful|uses|using|usually|v|value|various|versus|very|via|viz|vs|w|want|wants|was|wasn't|way|we|we'd|welcome|well|we'll|went|were|we're|weren't|we've|what|whatever|what'll|what's|what've|when|whence|whenever|where|whereafter|whereas|whereby|wherein|where's|whereupon|wherever|whether|which|whichever|while|whilst|whither|who|who'd|whoever|whole|who'll|whom|whomever|who's|whose|why|will|willing|wish|with|within|without|wonder|won't|would|wouldn't|x|y|yes|yet|you|you'd|you'll|your|you're|yours|yourself|yourselves|you've|z|zero)($| )/
  
  class << self
    attr_accessor :translation_to
    attr_accessor :translation_from

    # This method does the actual permalink escaping.
    def escape(string, seo_elim = false)
      result = ((translation_to && translation_from) ? Iconv.iconv(translation_to, translation_from, string) : string).to_s
      result.gsub!(SEO_WORD_REGEX, ' ') if ((result.size > 50) && seo_elim)
      result.gsub!(/[^\x00-\x7F]+/, '') # Remove anything non-ASCII entirely (e.g. diacritics).
      result.gsub!(/[^\w_ \-]+/i,   '') # Remove unwanted chars.
      result.gsub!(/[ \-]+/i,      '-') # No more than one of the separator in a row.
      result.gsub!(/^\-|\-$/i,      '') # Remove leading/trailing separator.
      result.downcase!
      result.size.zero? ? random_permalink(string) : result
    rescue
      random_permalink(string)
    end
    
    def random_permalink(seed = nil)
      Digest::SHA1.hexdigest("#{seed}#{Time.now.to_s.split(//).sort_by {rand}}")
    end
  end

  # This is the plugin method available on all ActiveRecord models.
  module PluginMethods
    # Specifies the given field(s) as a permalink, meaning it is passed through PermalinkFu.escape and set to the permalink_field.  This
    # is done
    #
    #   class Foo < ActiveRecord::Base
    #     # stores permalink form of #title to the #permalink attribute
    #     has_permalink :title
    #   
    #     # stores a permalink form of "#{category}-#{title}" to the #permalink attribute
    #   
    #     has_permalink [:category, :title]
    #   
    #     # stores permalink form of #title to the #category_permalink attribute
    #     has_permalink [:category, :title], :category_permalink
    #
    #     # add a scope
    #     has_permalink :title, :scope => :blog_id
    #
    #     # add a scope and specify the permalink field name
    #     has_permalink :title, :slug, :scope => :blog_id
    #
    #     # do not bother checking for a unique scope
    #     has_permalink :title, :unique => false
    #
    #     # update the permalink every time the attribute(s) change
    #     # without _changed? methods (old rails version) this will rewrite the permalink every time
    #     has_permalink :title, :update => true
    #
    #   end
    #
    def has_permalink(attr_names = [], permalink_field = nil, options = {})
      if permalink_field.is_a?(Hash)
        options = permalink_field
        permalink_field = nil
      end
      ClassMethods.setup_permalink_fu_on self do
        self.permalink_attributes = Array(attr_names)
        self.permalink_field      = (permalink_field || 'permalink').to_s
        self.permalink_options    = {:unique => true, :seo_eliminate => false}.update(options)
      end
    end
  end

  # Contains class methods for ActiveRecord models that have permalinks
  module ClassMethods
    def self.setup_permalink_fu_on(base)
      base.extend self
      class << base
        attr_accessor :permalink_options
        attr_accessor :permalink_attributes
        attr_accessor :permalink_field
      end
      base.send :include, InstanceMethods

      yield

      if base.permalink_options[:unique]
        base.before_validation :create_unique_permalink
      else
        base.before_validation :create_common_permalink
      end
      class << base
        alias_method :define_attribute_methods_without_permalinks, :define_attribute_methods
        alias_method :define_attribute_methods, :define_attribute_methods_with_permalinks
      end
    end

    def define_attribute_methods_with_permalinks
      if value = define_attribute_methods_without_permalinks
        evaluate_attribute_method permalink_field, "def #{self.permalink_field}=(new_value);write_attribute(:#{self.permalink_field}, new_value.blank? ? '' : PermalinkFu.escape(new_value, #{self.permalink_options[:seo_eliminate]}));end", "#{self.permalink_field}="
      end
      value
    end
  end

  # This contains instance methods for ActiveRecord models that have permalinks.
  module InstanceMethods
  protected
    def create_common_permalink
      return unless should_create_permalink?
      if read_attribute(self.class.permalink_field).blank? || permalink_fields_changed?
        send("#{self.class.permalink_field}=", create_permalink_for(self.class.permalink_attributes))
      end

      # Quit now if we have the changed method available and nothing has changed
      permalink_changed = "#{self.class.permalink_field}_changed?"
      return if respond_to?(permalink_changed) && !send(permalink_changed)

      # Otherwise find the limit and crop the permalink
      limit   = self.class.columns_hash[self.class.permalink_field].limit
      base    = send("#{self.class.permalink_field}=", read_attribute(self.class.permalink_field)[0..limit - 1])
      [limit, base]
    end

    def create_unique_permalink
      limit, base = create_common_permalink
      return if limit.nil? # nil if the permalink has not changed or :if/:unless fail
      counter = 1
      # oh how i wish i could use a hash for conditions
      conditions = ["#{self.class.permalink_field} = ?", base]
      unless new_record?
        conditions.first << " and id != ?"
        conditions       << id
      end
      if self.class.permalink_options[:scope]
        [self.class.permalink_options[:scope]].flatten.each do |scope|
          value = send(scope)
          if value
            conditions.first << " and #{scope} = ?"
            conditions       << send(scope)
          else
            conditions.first << " and #{scope} IS NULL"
          end
        end
      end
      while self.class.exists?(conditions)
        suffix = "-#{counter += 1}"
        conditions[1] = "#{base[0..limit-suffix.size-1]}#{suffix}"
        send("#{self.class.permalink_field}=", conditions[1])
      end
    end

    def create_permalink_for(attr_names)
      str = attr_names.collect { |attr_name| send(attr_name).to_s } * " "
      str.blank? ? PermalinkFu.random_permalink : str
    end

  private
    def should_create_permalink?
      if self.class.permalink_options[:if]
        evaluate_method(self.class.permalink_options[:if])
      elsif self.class.permalink_options[:unless]
        !evaluate_method(self.class.permalink_options[:unless])
      else
        true
      end
    end

    # Don't even check _changed? methods unless :update is set
    def permalink_fields_changed?
      return false unless self.class.permalink_options[:update]
      self.class.permalink_attributes.any? do |attribute|
        changed_method = "#{attribute}_changed?"
        respond_to?(changed_method) ? send(changed_method) : true
      end
    end

    def evaluate_method(method)
      case method
      when Symbol
        send(method)
      when String
        eval(method, instance_eval { binding })
      when Proc, Method
        method.call(self)
      end
    end
  end
end

if Object.const_defined?(:Iconv)
  PermalinkFu.translation_to   = 'ascii//translit//IGNORE'
  PermalinkFu.translation_from = 'utf-8'
end
