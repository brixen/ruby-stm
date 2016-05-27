# load all ruby_core_ext
require_relative 'custom_atomic_methods/object'
require_relative 'custom_atomic_methods/array'
require_relative 'custom_atomic_methods/hash'
require_relative 'object'

require_relative '../source_code/proc_source_code'
require_relative '../core/memory_transaction'
require_relative '../to_atomic/atomic_proc'

class Proc
  def source_code
    ProcSourceCode.new(self)
  end

  def atomic
    MemoryTransaction.do(to_atomic)
  end

  def atomic_if_conflict(a_block)
    MemoryTransaction.do_if_conflict(to_atomic, a_block)
  end

  def atomic_retry
    MemoryTransaction.do_and_retry(to_atomic)
  end

  def to_atomic
    AtomicProc.of(self)
  end
end