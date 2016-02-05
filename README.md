# Deserializer
## Features
- Hash transformation and sanitization
- Deserialization of complex parameters into a hash that an AR model can take
- Avoid having multiple definitions in fragile arrays when using strong params
- Easy create and update from JSON without writing heavy controllers
- [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers)-like interface and conventions

## Problem
Let's say we have an API with an endpoint that takes this JSON:

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

But this goes into a flat DishReview model:

```ruby
t.belongs_to  :restaurant
t.belongs_to  :user
t.string      :name # field name different from API (dish_name)
t.string      :description
t.string      :taste
t.string      :color
t.string      :texture
t.string      :smell
```

### Solution (No `Deserializer`)
Permit some params, do some parsing and feed that into `DishReview.new`:

```ruby
class DishReviewController < BaseController

  def create
    review_params = get_review_params(params)
    @review = DishReview.new(review_params)
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
    ["taste", "color", "texture", "smell"].include? rating
  end
end
```

#### What's up with that?
- You have to do this for every action
- Controllers are obese, hard to parse and fragile
- Controllers are doing non-controller-y things

### Solution (With `Deserializer`)
`DishReviewDeserializer`:

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

`RatingsDeserializer`:

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

All of this allows your controller to be so very small:

```ruby
class DishReviewsController < YourApiController::Base
  def create
    @review = DishReview.new( MyApi::V1::DishReviewDeserializer.from_params(params) )

    if @review.save
      # return review
    else
      # return sad errors splody
    end
  end

  # RUD
end
```

#### What's up with that?
- Un-pollutes controllers from all the parsing
- Builds deserializers that look like our serializers

## Definition
Inherit from `Deserializer::Base` and define it in much the same  way you would an [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

### attributes
Use `attributes` for straight mapping from params to the model:

```ruby
class PostDeserializer < Deserializer::Base
  attributes  :title,
              :body
end
```

```ruby
# Example params
{
    "title" => "lorem",
    "body"  => "ipsum"
}
# Resulting hash
   {
     title: "lorem",
     body: "ipsum"
   }
```

### attribute
Allows the following customizations for each `attribute`
#### :key

```ruby
class PostDeserializer < Deserializer::Base
  attribute :title, ignore_empty: true
  attribute :body, key: :content
end
```

`:content` here is what it will get in params while `:body` is what it will be inserted into the result.

```ruby
# Example params
{
    "title"   => "lorem",
    "content" => "ipsum"
}
# Resulting hash
  {
    title: "lorem",
    body: "ipsum"
  }
```

#### :ignore_empty
While `Deserializer`'s default is to pass all values through, this option will drop any key with `false`/`nil`/`""`/`[]`/`{}` values from the result.

```ruby
# Example params
{
    "title" => "",
    "text"  => nil
}
# Resulting hash
  {}
```

#### :convert_with
Allows deserializing and converting a value at the same time. For example:

```ruby
class Post < ActiveRecord::Base
  belongs_to :post_type # this is a domain table
end
```

If we serialize with

```ruby
class PostSerializer < ActiveModel::Serializer
  attribute :type

  def type
    object.post_type.symbolic_name
  end
end
```

Then, when we get a symbolic name from the controller but want to work with an id in the backend, we can:

```ruby
class PostDeserializer < Deserializer::Base
  attribute :title, ignore_empty: true
  attribute :body
  attribute :post_type_id, key: :type, convert_with: to_type_id

  def to_type_id(value)
    Type.find_by_symbolic_name.id
  end
end
```

```ruby
# Example params
{
    "title" => "lorem",
    "body"  => "ipsum",
    "type"  => "BLAGABLAG"
}
# Resulting hash
  {
    title: "lorem",
    body: "ipsum",
    post_type_id: 1
  }
```

### has_one
`has_one` association expects a param and its deserializer:

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

```ruby
# Example params
{
    "ratings" => {
        "taste" => "bad",
        "smell" => "good"
    }
}
# Resulting hash
  {
    ratings: {
      taste: "bad",
      smell: "good"
    }
  }
```

#### Deserialize into a Different Name
In the example above, if `ratings` inside `Dish` is called `scores` in your ActiveRecord, you can:

```ruby
class DishDeserializer < Deserializer::Base
  has_one :ratings, deserializer: RatingsDeserializer

  def ratings
    :scores
  end
end
```

```ruby
# Example params
{
    "ratings" => {
        "taste" => "bad",
        "smell" => "good"
    }
}
# Resulting hash
  {
    scores: {
      taste: "bad",
      smell: "good"
    }
  }
```

#### Deserialize into Parent Object
To deserialize `ratings` into the `dish` object, you can use `object`:

```ruby
class DishDeserializer < Deserializer::Base
  has_one :ratings, deserializer: RatingsDeserializer

  def ratings
    object
  end
end
```

```ruby
# Resulting hash
  {
    taste: "bad",
    smell: "good"
  }
```

#### Deserialize into a Different Sub-object

```ruby
class DishDeserializer < Deserializer::Base
  has_one :colors,  deserializer: ColorsDeserializer
  has_one :ratings, deserializer: RatingsDeserializer

  def colors
    :ratings
  end
end
```

Given params:

```ruby
# Example params
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
# Resulting hash
  {
    ratings: {
      taste: "bad",
      smell: "good",
      color: "red"
    }
  }
```

### has_many
`has_many` association expects a param and its deserializer:

```ruby
class DishDeserializer < Deserializer::Base
  # probably other stuff
  has_many :ratings, deserializer: RatingsDeserializer
end

class RatingsDeserializer < Deserializer::Base
  attributes  :user_id,
              :rating,
              :comment
end
```

```ruby
# Example params
{
  "ratings" => [
    { "user_id" => 6,
      "rating" => 3,
      "comment" => "not bad"
    },
    { "user_id" => 25,
      "rating" => 2,
      "comment" => "gross"
    }
  ]
}
# Resulting hash
  {
    ratings: [
      { user_id: 6,
        rating: 3,
        comment: "not bad"
      },
      { user_id: 25,
        rating: 2,
        comment: "gross"
      }
    ]
  }
```

#### key

You can deserialize a `has_many` association into a different key from what the json gives you. For example:
```json
{
  id: 6,
  name: "mac & cheese",
  aliases: [
    {
      id: 83,
      name: "macaroni and cheese"
    },
    {
      id: 86,
      name: "cheesy pasta"
    }
  ]
}
```

but your model is

```ruby
class Dish
  has_many :aliases
  accepted_nested_attributes_for :aliases
end
```
instead of renaming the hash in the controller, you can do

```ruby
class DishDeserializer < Deserializer::Base
  attributes  :id,
              :name

  has_many :aliases_attributes, deserializer: AliasDeserializer, key: :aliases
end
```

which would output

```ruby
{
  id: 6,
  name: "mac & cheese",
  aliases_attributes: [
    {
      id: 83,
      name: "macaroni and cheese"
    },
    {
      id: 86,
      name: "cheesy pasta"
    }
  ]
}
```

### nests
Sometimes you get a flat param list, but want it to be nested for `updated_nested_attributes`

If you have 2 models that look like

```ruby
class RestaurantLocation
  belongs_to :address
  # t.string :name
end

# where Address is something like
t.string      :line_1
t.string      :line_2
t.string      :city
t.string      :state
```

And you want to update them at the same time, as they're closely tied, `nests` lets you define

```ruby
class ResaturantLocationDeserializer < Deserializer::Base
  attribute :name

  nests :address, deserializer: AddressDeserializer
end

class AddressDeserializer
  attributes  :line_1,
              :line_2,
              :city,
              :state
end
```
And now you can take a single block of json

```ruby
# Example params into restaurant_location endpoint
{
  "name"    => "Little Caesars: Et Two Brute",
  "line_1"  => "2 Brute St.",
  "city"    => "Seattle",
  "state"   => "WA"
}

# Resulting hash
{
     name: "Little Caesars: Et Two Brute",
  address: {
      line_1: "2 Brute St",
        city: "Seattle",
       state: "WA"
  }
}

```



## Functions
### from_params
`MyDeserializer.from_params(params)` creates the JSON that your AR model will then consume.

```ruby
@review = DishReview.new( MyApi::V1::DishReviewDeserializer.from_params(params) )
```

### permitted_params
Just call `MyDeserializer.permitted_params` and you'll have the full array of keys you expect params to have.

## Installation
Add this line to your application's Gemfile:

```
gem 'deserializer'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install deserializer
```

## Contributing
1. Fork it ( [https://github.com/gaorlov/deserializer/fork](https://github.com/gaorlov/deserializer/fork) )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
