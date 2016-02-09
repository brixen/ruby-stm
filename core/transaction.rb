require_relative '../ruby_core_ext/thread'
require_relative 'object_change'

class Transaction
  def do(atomic_block)
    do_if_conflict(atomic_block, Proc.new { self.signal_conflict })
  end

  def do_if_conflict(atomic_block, on_conflict_block)
    Thread.set_current_transaction(self)
    begin_transaction
    begin
      begin
        result = atomic_block.call
      ensure
        Thread.set_current_transaction(nil)
      end
    rescue
      abort
      raise
    end
    commit_if_conflict(on_conflict_block)
    result
  end

  def retry(atomic_block)
    do_if_conflict(atomic_block, Proc.new { self.retry(atomic_block) })
  end

  def begin_transaction
    @object_changes = {}
  end

  def commit
    commit_if_conflict(Proc.new { self.signal_conflict })
  end

  def commit_if_conflict(on_conflict_block)
    @object_changes.each_value do |change|
      if change.has_conflict?
        return on_conflict_block.call
      end
    end
    @object_changes.each_value do |change|
      if change.has_changed?
        change.apply
      end
    end
    nil
  end

  def checkpoint
    commit
    begin_transaction
  end

  def abort
    @object_changes = nil
  end

  def signal_conflict
    raise 'CommitConflict'
  end

  def change_for(an_object)
    unless @object_changes.has_key?(an_object)
      @object_changes[an_object] = ObjectChange.new(an_object)
    end
    @object_changes[an_object]
  end
end