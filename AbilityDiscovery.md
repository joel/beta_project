Ability discovery #437

# Context

In an initiative started quite a long ago [Remove hard-coded model lists](https://pamsupport.atlassian.net/browse/IDEA-902) code detail [here](https://github.com/alliantist/PAM/commit/1c0a92d52b32a75a92b9a907015adde0ac5847ac) we did our best to get the list of models per abilities dynamically.

# Dynamic Search of Models per Abilities

It goes like that:

```ruby
module FooAbility

  module MacroMethods

    def acts_as_foo
      return if self.included_modules.include?(FooAbility::Predicates)

      include FooAbility::Predicates
    end

    def acts_as_foo?
      false
    end

  end

  module Predicates

    def self.included(base)

      base.class_eval do

        def self.acts_as_foo?
          true
        end

      end

    end

  end

end
```

After that, we extend the whole `ApplicationRecord`

```ruby
ApplicationRecord.extend FooAbility::MacroMethods
```

So now every single model is going to respond false to the predicate, aside from if it carries the ability:

```ruby
module Test

  class Anonymous < ApplicationRecord

  end

  class ActsAsFoo < ApplicationRecord

    acts_as_foo

  end

end

test "should not acts as foo" do
  assert_not Test::Anonymous.acts_as_foo?
end

test "should acts as foo" do
  assert Test::ActsAsFoo.acts_as_foo?
end
```

Sound straightforward so far.

What we want to achieve it that:

```ruby
test "list by ability" do
  assert_equal ["FooTest::Test::ActsAsFoo"], ApplicationRecord.descendants.filter(&:acts_as_foo?).map(&:name)
end
```

Here, the catch, aside from production, environments like development or test use lazy loading, so Rails is not aware of the models before we actually explicitly call them.

Taking a simple example to emphasize the issue (full code [here](https://github.com/joel/beta_project/tree/descendants) and [here](https://github.com/joel/beta_project/blob/edf83f29e03b5bf22b02f8656b9057659315d86f/test/lib/foo_ability_test.rb#L42-L61))

We have those 3 following models:

<img width="274" alt="Screen Shot 2022-02-17 at 9 04 08 AM" src="https://user-images.githubusercontent.com/5789/154431931-8a5fb034-1fb9-4c4c-ab70-fce13b669a1f.png">

```ruby
class Post < ApplicationRecord
end
```

```ruby
class Page < Post
end
```

```ruby
class Scrapbook < Page
  acts_as_foo
end
```

When we try to get them, we got that:

```ruby
test "descendants" do
  Test::Anonymous
  Test::ActsAsFoo

  assert_equal ["FooTest::Test::Anonymous", "FooTest::Test::ActsAsFoo", "Post"], ApplicationRecord.descendants.map(&:name)

  Page
  assert_equal ["FooTest::Test::Anonymous", "FooTest::Test::ActsAsFoo", "Post", "Page"], ApplicationRecord.descendants.map(&:name)

  Scrapbook
  assert_equal ["FooTest::Test::Anonymous", "FooTest::Test::ActsAsFoo", "Post", "Page", "Scrapbook"], ApplicationRecord.descendants.map(&:name)
end
```

We can clearly see the lazy loading in action.

So in order the keep our mechanism of auto-discovery base upon predicates working, we introduce a [Model Loader](https://github.com/joel/beta_project/blob/descendants-force-load/lib/model_loader.rb)

Now we are able to get it works:

```ruby
test "descendants" do
  assert_equal ["Page", "Post", "Scrapbook"], ModelLoader.models.map(&:name)
end

test "list by ability" do
  assert_equal ["Scrapbook"], ModelLoader.models.filter(&:acts_as_foo?).map(&:name)
end
```

# The problem

But what did we just do?

We simply loaded everything up, and it's exactly the same as turning on the eager loading.

```ruby
Rails.application.configure do
  config.eager_load = true
end
```

The issue with that is that aside from losing the benefit of autoloading, the Rails Core Team made clear that they want us to rely on that very same mechanism, and it will be mandatory in the future.

> [3.7 Autoloading during initialization](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloading-during-initialization)
Applications that autoloaded reloadable constants during initialization outside of to_prepare blocks got those constants unloaded and had this warning issued since Rails 6.0:

DEPRECATION WARNING: Initialization autoloaded the constant ....

Being able to do this is deprecated. Autoloading during initialization is going
to be an error condition in future versions of Rails.

> [2.1 Autoloaded paths are no longer in load path](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloaded-paths-are-no-longer-in-load-path)
> Starting from Rails 7.1, all paths managed by the autoloader will no longer be added to $LOAD_PATH. This means it won't be possible to load them with a manual require call, the class or module can be referenced instead.
>
> Reducing the size of $LOAD_PATH speed-up require calls for apps not using bootsnap, and reduce the size of the bootsnap cache for the others.

> [3.4 Applications need to run in zeitwerk mode](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#applications-need-to-run-in-zeitwerk-mode)
> Applications still running in classic mode have to switch to zeitwerk mode. Please check the [Classic to Zeitwerk HOWTO](https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html) guide for details.
>
> [3.5 The setter config.autoloader= has been deleted](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#the-setter-config-autoloader-has-been-deleted)
> In Rails 7 there is no configuration point to set the autoloading mode, config.autoloader= has been deleted. If you had it set to :zeitwerk for whatever reason, just remove it.
>
> [3.6 ActiveSupport::Dependencies private API has been deleted](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#activesupport-dependencies-private-api-has-been-deleted)
> The private API of ActiveSupport::Dependencies has been deleted. That includes methods like hook!, unhook!, depend_on, require_or_load, mechanism, and many others.

In other words, we are going against the current here, and it is a terrible idea.

# A Solution

How can we solve the issue without bending the framework?

I think a simple, straightforward static list of the models per ability is way around. (code [here](https://github.com/joel/beta_project/tree/descendants-static-list-load))

Getting back to the previous example, using a simple static list

config/ability_mapping.json
```json
{
  "acts_as_foo": [
    "Scrapbook"
  ]
}
```

A Loader
```ruby
module AbilityModel
  module_function

  def ability(ability)
    mapping[ability.to_s] || []
  end

  def mapping
    @mapping ||= begin
      mapping_path = Pathname.new(Rails.root.join('config/ability_mapping.json'))
      JSON.load(mapping_path)
    end
  end

end
```

And that it:
```ruby
  test "list by ability" do
    assert_equal ["Scrapbook"], AbilityModel.ability(:acts_as_foo)
  end
```

The fact is straightforward to understand and maintain, and it is highly performant.

### Now, how to keep that list in check?

We can rely on our CI for that, and this is what we already do for many parts of our codebase, like when we check the [versiones fields](https://github.com/alliantist/PAM/blob/master/script/checks/report_non_versioned_fields)

With a [AbilityCheck](https://github.com/joel/beta_project/blob/descendants-static-list-load/lib/ability_check.rb)

```ruby
test "should check" do
  error = assert_raises(AbilityCheck::AbilityInconsistency) do
    AbilityCheck.new.check!
  end
  assert_equal "MISSING MAPPING FOR [Pages::Header]", error.message
end
```

# Conclusion

We try to be very smart here when we simply shouldn’t. When red flags stand up one after another, we should stop and rethink our approach. I might have been wrong, and I really need your feedback and input on that because we have already spent a significant amount of time trying to make that work.
