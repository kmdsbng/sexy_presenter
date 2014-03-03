# SexyPresenter - Most powerful Rails presentation layer gem ever.

[![Build Status](https://travis-ci.org/kmdsbng/sexy_presenter.png?branch=master)](https://travis-ci.org/kmdsbng/sexy_presenter)

SexyPresenter add presentation logic to your Rails application.
To inject presentation logic in view, SexyPresenter use Refinements feature that added Ruby in version 2.1.


## Features

SexyPresenter provides only 2 features.

1. You can assign presenters in view files.
2. You can use `before_render` hook in presentation file.


## Assign presenter

Assign presenter in your view file's frontmatter.
(SexyPresenter supports any template engines, e.g. .erb, .haml, .slim .)

### sample.erb
```erb
---
presenter: MessagePresenter
---
<% @messages.each do |m| %>
<%= m.title %>,<%= m.body %>,<%= m.body_length_type %>
<% end %>
```

In this case, `Message` class has title and body fields in `models/message.rb`.
But it does not have body_length_type method because body_length_type related only this page.

So, you implement body_length_type method to `Message` class in `MessagePresenter` module using Refinements.
We suggest you to implement `MessagePresenter` in `app/presenters/message_presenter`,
but actually you can make the file in any autoload target directory, or in `config/initializers`.

### app/presenters/message_presenter.rb
```ruby
module MessagePresenter
  refine Message
    def body_length_type
      if self.body.length > 100
        'LONG'
      elsif self.body.length > 50
        'MIDDLE'
      else
        'SHORT'
      end
    end
  end
end
```

This code works well.

`body_length_type` method is activated only in `sample.erb`.
This is nothing more than Refinements behavior.

## `before_render` hook

If you want special initialization logic to a view file, you can use `before_render` hook.

### _header.erb
```erb
---
presenter: HeaderPresenter
---
Welcome to our web site.
Now we have <%= @customer_count %> customers. Join us!
```

### app/presenters/header_presenter.rb
```ruby
module HeaderPresenter
  before_render do
    @customer_count = ::Customer.count
  end
end
```

`before_render` block runs in view context.




## Requirement

SexyPresenter depends on Ruby's Refinements feature.

* Rails 4.0.3 or later.
* Ruby 2.1 or later. (depend on Refinements feature)



This project rocks and uses MIT-LICENSE.


## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

