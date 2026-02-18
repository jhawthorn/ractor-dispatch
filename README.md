# Ractor::Dispatch

Dispatch work to a specific Ractor and get results back. The primary use case
is an "escape hatch" for code running in non-main Ractors that needs to execute
something only the main Ractor can do (access globals, unshareable constants,
ENV, etc).

## Usage

```ruby
require "ractor/dispatch"

Ractor.new do
  # Synchronous — blocks until the main Ractor returns the result
  home = Ractor::Dispatch.main.run { ENV["HOME"] }
  puts home

  # Async — returns a Future immediately
  future = Ractor::Dispatch.main.submit { ENV["PATH"] }
  # ... do other work ...
  path = future.value
end.join
```

The passed block is automatically made into a shareable proc. Because shareable
procs can close over frozen/shareable values, this works naturally with frozen
string literals and other shareable objects.

### Error handling

Exceptions raised by the block are propagated back to the caller:

```ruby
Ractor.new do
  Ractor::Dispatch.main.run { raise "oops" } # => raises RuntimeError "oops"
end.join
```

### Shutdown

```ruby
Ractor::Dispatch.main.shutdown # closes the work port, background thread exits
```

### Custom executors

`Ractor::Dispatch.main` is a convenience for the common case. You can also
create your own executor on any Ractor:

```ruby
executor = Ractor::Dispatch::Executor.new

Ractor.new(executor) do |ex|
  ex.run { ENV["HOME"] }
end.join
```

## How it works

`Ractor::Dispatch.main` lazily creates an `Executor` on the main Ractor.
`Executor.new` creates a `Ractor::Port` and spawns a background `Thread` on
the current Ractor that loops receiving work from the port. The Executor is
then made shareable so it can be passed to other Ractors.

When `submit` is called, the block is made into a shareable proc, the caller
creates a reply `Ractor::Port`, sends `[callable, args, reply_port]` to the
executor's work port, and returns a `Future` wrapping the reply port. The
background thread receives the job, executes it, and sends the result back on
the reply port.

The key `Ractor::Port` property that makes this work: **any Ractor can send
to a port, but only the creating Ractor can receive from it**. This means
reply ports naturally route results back to the correct caller.

## Requirements

Requires Ruby with `Ractor::Port` support (Ruby 4.0+).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/ractor-dispatch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jhawthorn/ractor-dispatch/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ractor::Dispatch project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jhawthorn/ractor-dispatch/blob/main/CODE_OF_CONDUCT.md).
