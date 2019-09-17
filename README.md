# Service Operation

This gem is based on code from:

https://github.com/collectiveidea/interactor

https://github.com/michaelherold/interactor-contracts

https://github.com/tomdalling/value_semantics

I've used the 'interactor' gem for many years but developement on it had slowed down and I wanted
more control over defining parameter constraints. 'interactor-contracts' provided a great model for
this but it had dependencies on the dry-validation gem which at the time was still pre 1.0 and
undergoing a lot of change but also moving very slowly. Due to the complexity of how
'interactor-contracts' dynamically generated schema clases (in combination with a bug in dry-rb)
it seemed simpler to combine the code bases than tinker with complex internals that were subject
to change anyway.

So this library is a mash up of 'interactor' and 'value_semantics' by @tomdalling, which provided a
simpler, more elegant, basis for some basic parameter validation/coercion. For more complex
schemas 'dry-validation' or 'parametric' can be laid on top.

## Minimal Example

Does not demonstrate many of the coercion and validation features.

```ruby
class AuthenticateUser
  include ServiceOperation::Base

  param do
    email :string
    password :string
  end

  # unless optional, returns are checked via method after `#call` so these values will be fetched
  # regardless of whether they're used and the operation will fail if they return nil.
  returns do
    user :user
    token :string

    user_id :integer

    # the params (email and password) will also be returned
  end

  before do
    # some filter logic (around and after are also implemented)
    fail!(email: 'must be valid') if email !~ User::EMAIL_REGEXP
  end

  around do |op|
    # start instrumentation
    op.call
    # stop instrumentation
  end

  after do
    fail_unless_persisted?(user)
  end

  # this whole call method is actually unnecessary as :user is a required return value
  # so commented out it would fail with { base: 'user cannot be blank' }
  def call
    fail!(message: 'authenticate_user.failure') unless user
  end

  private

  def user
    context.fetch { User.authenticate(email, password) }
  end

  def user_id
    contex.fetch { user.id }
  end

  def token
    context.fetch { user.secret_token }
  end
end

class SessionsController < ApplicationController
  def create
    result = AuthenticateUser.call(session_params)

    if result.success?
      session[:user_token] = result.token
      redirect_to result.user
    else
      flash.now[:message] = t(result.message)
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end

```

Example parameter DSL:

```ruby

params do
  # coercion
  user :user, coerce: -> (user) {user === User ? user : User.find_by_email(user) }

  # optional values will be coerced but not fail if blank.
  referrer :string, optional: true

  # default values
  subject :string, default: 'No Subject'

  # Arrays with mixed types
  numbers [:integer, :float], default: [1, 1.5, 2]

  # The ValueSemantics DSL using mix of actual classes and types
  activate Bool, default: false
  timestamp Any(DateTime, Time), default: -> { Time.now }
  media_assets ArrayOf(Jpg, Mp3)
  payload Anything
end

```

## Development

`docker-compose run app`

or

`docker-compose run app guard`