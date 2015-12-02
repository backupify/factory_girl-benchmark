# FactoryGirl::Benchmark

benchmark your top-level factory_girl factories

## Installation

```rb
gem 'factory_girl-benchmark'
```

## Usage

Here's an example of how we use it in our test helper:

```rb
if ENV['FG_BENCH']
  require 'factory_girl/benchmark'
  FactoryGirl.singleton_class.prepend(FactoryGirl::Benchmark)
  # Register before minitest to have minitest run first
  at_exit { FactoryGirl::Benchmark.report }
end
```

You could also use the example which will run all of your factories:

```rb
FactoryGirl::Benchmark.benchmark!
```
