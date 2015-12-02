require 'factory_girl/benchmark/version'
require 'factory_girl'
require 'colorize'

module FactoryGirl
  module Benchmark
    %i{create build build_stubbed attributes_for build_list create_list build_pair create_pair}.each do |sym|
      define_method(sym) do |*args, &block|
        if FactoryGirl::Benchmark.is_benching?
          super *args, &block
        else
          FactoryGirl::Benchmark.bm(sym, args) do
            super *args, &block
          end
        end
      end
    end

    class << self
      # Example usage
      def benchmark!
        # Install
        FactoryGirl.singleton_class.prepend(FactoryGirl::Benchmark)

        # Run
        FactoryGirl.find_definitions if FactoryGirl.factories.none?
        FactoryGirl.factories.map(&:name).each do |f|
          begin
            FactoryGirl.create(f)
          rescue => e
            puts "Couldn't benchmark factory #{f} due to #{e}"
          end
        end

        # Report
        FactoryGirl::Benchmark.report
      end

      def benchmarks
        @benchmarks ||= {}
      end

      def is_benching?
        @benching
      end

      def bm(sym, args)
        benching = true
        rv = nil

        bm = ::Benchmark.measure { rv = yield }

        record = { sym: sym, bm: bm.real, args: args, bt: caller.select {|x| x[/#{Rails.root}/]} }
        key = "FactoryGirl.#{sym}##{args.first}"
        benchmarks[key] ||= []
        benchmarks[key] << record

        rv
      ensure
        benching = false
      end

      def benching=(o)
        @benching = o
      end

      def report
        puts 'Most frequent'
        r = benchmarks.reduce([]) do |m, (k, _)|
          m << { key: k, count: benchmarks[k].size }
        end.sort {|a,b| b[:count] <=> a[:count]}
        print_report(r)

        puts 'Slowest instances'
        r = benchmarks.each_value.to_a.flatten.sort {|a,b| b[:bm] <=> a[:bm]}
        print_report(r)

        puts 'Slowest total'
        r = benchmarks.reduce([]) do |m, (k, _)| 
          m << { key: k, count: benchmarks[k].size, total_time: benchmarks[k].reduce(0) {|sum, bm| sum + bm[:bm]} }
        end.sort {|a,b| b[:total_time] <=> a[:total_time]}
        print_report(r)

        puts 'Slowest average'
        r = benchmarks.reduce([]) do |m, (k, _)| 
          total_time = benchmarks[k].reduce(0) {|sum, bm| sum + bm[:bm]}
          count = benchmarks[k].size
          m << { key: k, avg: total_time.to_f/count, count: count, total_time: total_time }
        end.sort {|a,b| b[:avg] <=> a[:avg]}
        print_report(r)
      end

      def print_report(arr)
        require 'colorize'
        arr.first(20).map {|h| puts "\t#{h}".colorize(color)}
        puts
      end

      def color
        @last_color = case @last_color
                      when nil then :yellow
                      when :yellow then :light_cyan
                      when :light_cyan then :yellow
                      end
      end
    end
  end
end
