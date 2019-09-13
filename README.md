# Service Operation

This gem is based on code from:

https://github.com/tomdalling/value_semantics

https://github.com/collectiveidea/interactor

https://github.com/michaelherold/interactor-contracts

I've used `Interactor` for many years but developement on it had slowed down and I wanted more
control over defining parameter constraints. `Interactor::Contracts` provided a great model for this
but had dependencies on `Dry::Validation` which is a moving target. So this gem is a mash up of
`Interactor` and `ValueSemantics` by @tomdalling, which provided a simpler, more elegant basis
for some basic parameter validation/coercion.

## Minimal Example

Does not demonstrate many of the coercion and validation features.

```ruby
class AuthenticateUser
  include ServiceOperation::Base

  param do
    email :string
    password :string
  end

  returns do
    user :user
    token :string                   # will be fetched after call, service will fail if nil

    user_id :integer                # will be fetched after call
    status :string, optional: true  # won't be fetched or validated
  end

  before do
    # some filter logic
  end

  def call
    fail!(message: "authenticate_user.failure") unless user
  end

  private

  def user
    context.fetch { User.authenticate(email, password) }
  end

  def user_id
    contex.fetch { user.id }
  end

  def token
    context.fetch { user.secret_token } # service fails if this returns nil
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

## Development

`docker-compose run app`

or

`docker-compose run app guard`