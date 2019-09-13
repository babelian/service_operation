# frozen_string_literal: true

# ServiceOperation
module ServiceOperation
  autoload :Base, 'service_operation/base'
  autoload :Context, 'service_operation/context'
  autoload :Delay, 'service_operation/delay'
  autoload :Errors, 'service_operation/errors'
  autoload :ErrorHandling, 'service_operation/error_handling'
  autoload :Failure, 'service_operation/failure'
  autoload :Hooks, 'service_operation/hooks'
  autoload :Input, 'service_operation/input'
  autoload :Params, 'service_operation/params'
  autoload :RackMountable, 'service_operation/rack_mountable'
  autoload :Validations, 'service_operation/validations'
  autoload :VERSION,  'service_operation/version'
end