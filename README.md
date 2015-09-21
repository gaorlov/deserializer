# Deserializer

Hash transformation and sanitization. Deserialization of complex parameters into a hash that an AR model can take. 

Lets you have a reverse ActiveModel::Sereializer-like interface that allows for easy create and update without having to write heavy controllers.

## Problem

Let's say we have a API create endpoint that takes json that looks something like

```json
{
  "restaurant_id" : 13,
        "user_id" : 6,
      "dish_name" : "risotto con funghi",
    "description" : "repulsive beyond belief",
        "ratings" : {
                        "taste" : "terrible",
                        "color" : "horrendous",
                      "texture" : "vile",
                        "smell" : "delightful, somehow"
                    }
}
```

that goes into a flat DishReview model that looks like

```ruby
t.belongs_to  :restaurant
t.belongs_to  :user
# field name different from API
t.string      :name
t.string      :description
t.string      :taste
t.string      :color
t.string      :texture
t.string      :smell
```

what do we do?

Normally, we'd have some params we permit, do some parsing and feed those into `DishReview.new`, like

``` ruby
class DishReviewController < BaseController

  def create
    review_params = get_review_params(params)
    @review = ProfessionalReview.new(review_params)
    if @review.save
      # return review
    else
      # return sad errors splody
    end
  end

  # rest of RUD

  protected

  def permitted_params
   [
      :restaurant_id,
      :user_id
      :dish_name,
      :description,
      :taste,
      :color,
      :texture,
      :smell
    ]
  end

  def get_review_params(params)
    review_params = params.require(:review)

    review_params[:name] ||= review_params.delete(:dish_name)

    ratings = review_params.delete(:ratings)
    if (ratings.present?)
      ratings.each{|rating, value| review_params[rating] = value if valid_rating?(rating) }
    end

    review_params.permit(permitted_params)
  end

  def valid_rating?(rating)
    @@ratings ||= ["overall", "trusthworthy", "responsive", "knowledgeable", "communication"]

    @@ratings.include? rating

  end
end
```

and that's fine, but kind of annoying, and you have to do this for every action. It makes the controllers heavy, hard to parse, fragile, and really do things that are no longer controller-y. 

So what we have here is a wrapper that lets us get away from polluting the controller with all of this parsing and lets us build deserializers that look very much like our serializers. 

## Usage

Deserializer acts and looks pretty mich identical to ActiveModel::Serializer. It has attributes, attribute, and the has_one association. It does not currently support has_many, as that's an odd thing for a write endpoint to support, but can easily be added. 

### Deserializer functions

#### from_params
`MyDeserializer.from_params(params)` created the json that your AR model will then consume. 
```ruby
@review = DishReview.new( MyApi::V1::DishReviewDeserailzer.from_params(params) )
```

#### permitted_params
If you're using strong params, this lets you avoid having multiple definitions in fragile arrays. Just call ` MyDeserailzer.permitted_params` and you'll have the full array of keys you expect params to have.

### Deserializer Definition
To define a deserializer, you inherit from `Deserializer::Base` and define it in much the same way you would an `ActiveModel::Serializer`. 

#### attributes
This is straight 1:1 mapping from params to the model, so 

```ruby
class PostDeserializer < Deserializer::Base
  attributes  :title,
              :body
end
```
with params `{"title" => "lorem", "body" => "ipsum"}`, will give you a hash of `{title: "lorem", body: "ipsum"}`.

#### attribute
`attribute` is the singular version of `attributes`, but like `ActiveModel::Serializer` it can take a `:key`
```ruby
class PostDeserializer < Deserializer::Base
  attribute :title, ignore_empty: true
  attribute :body, key: :text
end
```
It is symmetric with `ActiveModel::Serializer`, so that :text is what it will get in params, but :body is what it will insert into the result. 

For example with params of `{"title" => "lorem", "text" => "ipsum"}` this desrerializer will produce `{title: "lorem", body: "ipsum"}`.

`ignore_empty` is an option to ignore `false`/`nil`/`""`/`[]`/`{}` values that may come into the deserializer. By defualt it will pass the value through. With this option, it will drop the key from the result, turning `{"title" => "", "text" => nil}` into `{}`

`convert_with` allows the deserializer to deserialize and convert a value at the same time. For example, if we have a `Post` model that looks like

```ruby 
class Post < ActiveRecord::Base
  belongs_to :post_type # this is a domain table
end
```

and we serialize with 
```ruby
class PostSerializer < ActiveModel::Serializer
  attribute :type

  def type
    object.post_type.symbolic_name
  end
end
```

Then, when we if we get a symbolic name from the controller, but want to work with an id in the backend, we can do something like:

```ruby
class PostDeserializer < Deserializer::Base
  attribute :title, ignore_empty: true
  attribute :body
  attribute :post_type_id, key: type, convert_with: to_type_id

  def to_type_id(value)
    Type.find_by_symbolic_name.id
  end
end
```

which would take the params `{"title" => "lorem", "body" => "ipsum", "type" => "BLAGABLAG"}` and produce `{title: "lorem", body: "ipsum", post_type_id: 1}`


#### has_one
NOTE: This is the only association currently supported by `Deserializer`.
`has_one` expects the param and its deserializer.
```ruby 
class DishDeserializer < Deserializer::Base
  # probably other stuff
  has_one :ratings, deserializer: RatingsDeserializer
end

class RatingsDeserializer < Deserializer::Base
  attributes  :taste,
              :smell
end
```
So for params `{"ratings" => {"taste" => "bad", "smell" => "good"}}` you would get `{ratings: {taste: "bad", smell: "good"}}`

#### Overriding Attribute Methods
So let's say in the example above, your internal representation of ratings inside `Dish` is actually called `scores`, you can do
```ruby
class DishDeserializer < Deserializer::Base
  has_one :ratings, deserializer: RatingsDeserializer

  def ratings
    :scores
  end
end
```
which will give you `{scores: {taste: "bad", smell: "good"}}` for params `{"ratings" => {"taste" => "bad", "smell" => "good"}}`

or, if you want to deserialize `ratings` into your `dish` object, you can use `object`

```ruby
class DishDeserializer < Deserializer::Base
  has_one :ratings, deserializer: RatingsDeserializer

  def ratings
    object
  end
end
```
which will give you `{taste: "bad", smell: "good"}` for params `{"ratings" => {"taste" => "bad", "smell" => "good"}}`

or you can deserialize into another subobject by doing
```ruby
class DishDeserializer < Deserializer::Base
  has_one :colors,  deserializer: ColorsDeserializer
  has_one :ratings, deserializer: RatingsDeserializer

  def colors
    :ratings
  end
end
```
which, given params 
```
{ 
  "ratings" => 
    { 
      "taste" => "bad",
      "smell" => "good"
    }, 
  "colors" => 
    { 
      "color" => "red"
    }
}
```
, will give you `{ratings: {taste: "bad", smell: "good", color: "red"}}`

### Example

So the example above will combine all of those to look like 

```ruby
module MyApi
  module V1
    class DishReviewDeserializer < Deserializer::Base
      attributes  :restaurant_id
                  :user_id
                  :description

      attribute   :name, key: :dish_name

      has_one :ratings, :deserializer => RatingsDeserializer

      def ratings
        object
      end

    end
  end
end
```

where RatingsDeserializer looks like

```ruby
module MyApi
  module V1
    class RatingsDeserializer < Deserializer::Base

      attributes  :taste,
                  :color,
                  :texture,
                  :smell
    end
  end
end
```

All of this allows your controller to be so very small, like

```ruby
class DishReviewsController < YourApiController::Base
  def create
    @review = DishReview.new( MyApi::V1::DishReviewDeserailzer.from_params(params) )

    if @review.save
      # return review
    else
      # return sad errors splody
    end
  end

  # RUD
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'deserializer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deserializer


## Contributing

1. Fork it ( https://github.com/[my-github-username]/deserializer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
