require 'benchmark'
puts '==> Start benchmark: ./core-features/bm_vm1_block.rb'
Benchmark.bm(7) do |bmr|
  bmr.report {
### End header added by script ###

  def m
    yield
  end
  
  i=0
  while i<30000000 # while loop 1
    i+=1
    m{
    }
  end

### Begin footer added by script ###
}
end
puts '==> End benchmark: ./core-features/bm_vm1_block.rb'